// Eenmalig opruimscript voor closed-testing-accounts. Spiegelt exact wat
// AccountDeletionService.deleteMyAccount() in de app zelf doet (zie
// lib/services/account_deletion_service.dart), maar dan via de Admin SDK
// voor een hele lijst testers tegelijk — zij hoeven zelf niks te doen.
//
// Gebruik:
//   1. Firebase Console -> Project settings -> Service accounts ->
//      "Generate new private key" -> opslaan als functions/serviceAccountKey.json
//      (staat al in .gitignore, commit dit bestand nooit)
//   2. Vul TESTER_EMAILS hieronder in
//   3. cd functions && node scripts/cleanup-testers.js
//      (draai eerst zonder --confirm om te zien wat er verwijderd zou worden)
//   4. node scripts/cleanup-testers.js --confirm

const admin = require("firebase-admin");
const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "the-box-community.firebasestorage.app",
});

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage();

const TESTER_EMAILS = [
  // "voorbeeld+tester1@gmail.com",
];

const DRY_RUN = !process.argv.includes("--confirm");

async function deleteWhereEquals(collection, field, uid) {
  const snapshot = await db.collection(collection).where(field, "==", uid).get();
  for (const doc of snapshot.docs) {
    console.log(`  - ${collection}/${doc.id}`);
    if (!DRY_RUN) await doc.ref.delete();
  }
}

async function deletePhotoPosts(uid) {
  const snapshot = await db.collection("photo_posts").where("uid", "==", uid).get();
  for (const doc of snapshot.docs) {
    const imageUrl = doc.data().imageUrl;
    console.log(`  - photo_posts/${doc.id}${imageUrl ? " (+ storage file)" : ""}`);
    if (!DRY_RUN) {
      if (imageUrl) {
        try {
          const path = decodeURIComponent(new URL(imageUrl).pathname.split("/o/")[1].split("?")[0]);
          await storage.bucket().file(path).delete();
        } catch (e) {
          console.log(`    (storage file al weg of onbereikbaar: ${e.message})`);
        }
      }
      await doc.ref.delete();
    }
  }
}

async function deleteReactionsOnWallOfFame(uid) {
  const snapshot = await db.collection("wall_of_fame_posts").get();
  for (const doc of snapshot.docs) {
    const reactions = doc.data().reactionsByUser || {};
    if (reactions[uid] !== undefined) {
      console.log(`  - reactie op wall_of_fame_posts/${doc.id}`);
      if (!DRY_RUN) {
        await doc.ref.update({ [`reactionsByUser.${uid}`]: admin.firestore.FieldValue.delete() });
      }
    }
  }
}

async function deleteCommentsAndPollVotesOnSocialPosts(uid) {
  const snapshot = await db.collection("social_posts").get();
  for (const postDoc of snapshot.docs) {
    const comments = await postDoc.ref.collection("comments").where("authorUid", "==", uid).get();
    for (const commentDoc of comments.docs) {
      console.log(`  - comment op social_posts/${postDoc.id}/comments/${commentDoc.id}`);
      if (!DRY_RUN) await commentDoc.ref.delete();
    }

    const pollVotes = postDoc.data().pollVotesByUser || {};
    if (pollVotes[uid] !== undefined) {
      console.log(`  - pollstem op social_posts/${postDoc.id}`);
      if (!DRY_RUN) {
        await postDoc.ref.update({ [`pollVotesByUser.${uid}`]: admin.firestore.FieldValue.delete() });
      }
    }
  }
}

async function cleanupTester(email) {
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
  } catch (e) {
    console.log(`${email}: geen account gevonden (${e.message}), overgeslagen`);
    return;
  }

  const uid = userRecord.uid;
  console.log(`\n=== ${email} (uid: ${uid}) ===`);

  await deleteWhereEquals("wall_of_fame_posts", "authorUid", uid);
  await deleteWhereEquals("social_posts", "authorUid", uid);
  await deleteWhereEquals("wod_scores", "uid", uid);
  await deleteWhereEquals("news_posts", "authorUid", uid);
  await deleteWhereEquals("agenda_events", "authorUid", uid);
  await deleteWhereEquals("race_results", "uid", uid);
  await deleteWhereEquals("challenge_results", "uid", uid);

  for (const lift of ["deadlift", "benchPress", "backSquat", "shoulderPress"]) {
    const ref = db.collection("lift_prs").doc(`${uid}_${lift}`);
    const doc = await ref.get();
    if (doc.exists) {
      console.log(`  - lift_prs/${uid}_${lift}`);
      if (!DRY_RUN) await ref.delete();
    }
  }

  await deletePhotoPosts(uid);
  await deleteReactionsOnWallOfFame(uid);
  await deleteCommentsAndPollVotesOnSocialPosts(uid);

  console.log(`  - user_profiles/${uid}`);
  console.log(`  - auth user ${uid}`);
  if (!DRY_RUN) {
    await db.collection("user_profiles").doc(uid).delete();
    await auth.deleteUser(uid);
  }
}

async function main() {
  if (TESTER_EMAILS.length === 0) {
    console.log("TESTER_EMAILS is leeg — vul de lijst in dit script eerst in.");
    return;
  }

  console.log(DRY_RUN ? "DRY RUN — er wordt niks verwijderd, alleen getoond wat het zou doen.\nDraai met --confirm om echt te verwijderen.\n" : "LIVE RUN — dit verwijdert nu echt data.\n");

  for (const email of TESTER_EMAILS) {
    await cleanupTester(email);
  }

  console.log("\nKlaar.");
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
