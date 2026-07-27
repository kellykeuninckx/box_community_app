const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {getStorage} = require("firebase-admin/storage");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();
const storage = getStorage();

/**
 * Stuurt een melding naar één specifieke gebruiker, maar alleen als ze een
 * token hebben en de betreffende voorkeur niet hebben uitgezet.
 */
async function sendToUser(uid, preferenceField, title, body, data) {
  const profileDoc = await db.collection("user_profiles").doc(uid).get();

  if (!profileDoc.exists) {
    console.log(`[sendToUser] Geen profiel gevonden voor uid ${uid}, niks verstuurd.`);
    return;
  }

  const profile = profileDoc.data();
  const token = profile.fcmToken;
  const wantsThis = profile[preferenceField] !== false;

  if (!token) {
    console.log(`[sendToUser] Geen fcmToken voor uid ${uid}, niks verstuurd.`);
    return;
  }

  if (!wantsThis) {
    console.log(`[sendToUser] uid ${uid} heeft ${preferenceField} uitstaan, niks verstuurd.`);
    return;
  }

  try {
    await messaging.send({
      token,
      notification: {title, body},
      ...(data ? {data} : {}),
    });
    console.log(`[sendToUser] Melding succesvol verstuurd naar uid ${uid}: "${title}"`);
  } catch (error) {
    console.error(`[sendToUser] Melding versturen naar ${uid} mislukt:`, error);
  }
}

/**
 * Stuurt een melding naar iedereen die de Nieuws & Agenda-voorkeur aan heeft staan.
 */
async function notifyAllForNewsAndAgenda(title, body, data) {
  const snapshot = await db
      .collection("user_profiles")
      .where("notifyNewsAndAgenda", "==", true)
      .get();

  const tokens = snapshot.docs
      .map((doc) => doc.data().fcmToken)
      .filter((token) => !!token);

  console.log(`[notifyAllForNewsAndAgenda] ${snapshot.docs.length} profielen met voorkeur aan, ${tokens.length} met een token.`);

  if (tokens.length === 0) {
    console.log("[notifyAllForNewsAndAgenda] Geen tokens gevonden, niks verstuurd.");
    return;
  }

  try {
    await messaging.sendEachForMulticast({
      tokens,
      notification: {title, body},
      ...(data ? {data} : {}),
    });
    console.log(`[notifyAllForNewsAndAgenda] Verstuurd naar ${tokens.length} tokens: "${title}"`);
  } catch (error) {
    console.error("[notifyAllForNewsAndAgenda] Versturen mislukt:", error);
  }
}

// 1. Reactie (emoji) op een Wall of Fame-post
exports.onWallOfFameReaction = onDocumentUpdated("wall_of_fame_posts/{postId}", async (event) => {
  const postId = event.params.postId;
  const before = event.data.before.data();
  const after = event.data.after.data();

  const beforeReactions = before.reactionsByUser || {};
  const afterReactions = after.reactionsByUser || {};

  const newReactorUid = Object.keys(afterReactions).find(
      (uid) => !(uid in beforeReactions),
  );

  if (!newReactorUid) {
    console.log("[onWallOfFameReaction] Geen nieuwe reactie gevonden (waarschijnlijk een andere wijziging of een ingetrokken reactie), niks gedaan.");
    return;
  }

  const authorUid = after.authorUid;

  if (!authorUid) {
    console.log("[onWallOfFameReaction] Post heeft geen authorUid, niks gedaan.");
    return;
  }

  if (authorUid === newReactorUid) {
    console.log("[onWallOfFameReaction] Iemand reageerde op hun eigen post, bewust geen melding.");
    return;
  }

  const reactorDoc = await db.collection("user_profiles").doc(newReactorUid).get();
  const reactorName = reactorDoc.exists ? (reactorDoc.data().nickname || "Iemand") : "Iemand";
  const emoji = afterReactions[newReactorUid];

  console.log(`[onWallOfFameReaction] Nieuwe reactie van ${reactorName} (${emoji}) op post van uid ${authorUid}.`);

  await sendToUser(
      authorUid,
      "notifyWallOfFameReactions",
      "Nieuwe reactie op je Wall of Fame-post",
      `${reactorName} reageerde met ${emoji}`,
      {type: "wall_of_fame_post", postId},
  );
});

// 2. Reactie in het Koffiehoekje
exports.onKoffiehoekjeComment = onDocumentCreated(
    "social_posts/{postId}/comments/{commentId}",
    async (event) => {
      const comment = event.data.data();
      const postId = event.params.postId;

      const postDoc = await db.collection("social_posts").doc(postId).get();
      if (!postDoc.exists) {
        console.log(`[onKoffiehoekjeComment] Post ${postId} niet gevonden, niks gedaan.`);
        return;
      }

      const post = postDoc.data();
      const authorUid = post.authorUid;

      if (!authorUid || authorUid === comment.authorUid) {
        console.log("[onKoffiehoekjeComment] Eigen post, of geen authorUid — bewust geen melding.");
        return;
      }

      console.log(`[onKoffiehoekjeComment] Nieuwe reactie van ${comment.authorNickname} op post van uid ${authorUid}.`);

      await sendToUser(
          authorUid,
          "notifyKoffiehoekjeReactions",
          "Nieuwe reactie in het Koffiehoekje",
          `${comment.authorNickname}: ${comment.text}`,
      );
    },
);

// 3. Nieuw nieuwsbericht
exports.onNewsPostCreated = onDocumentCreated("news_posts/{postId}", async (event) => {
  const post = event.data.data();
  const postId = event.params.postId;
  console.log(`[onNewsPostCreated] Nieuw bericht: "${post.title}"`);
  await notifyAllForNewsAndAgenda(
      "Nieuw bericht",
      post.title || "Er staat een nieuw bericht klaar.",
      {type: "news_post", postId},
  );
});

// 4. Nieuw agenda-event
exports.onAgendaEventCreated = onDocumentCreated("agenda_events/{eventId}", async (event) => {
  const agendaEvent = event.data.data();
  console.log(`[onAgendaEventCreated] Nieuw event: "${agendaEvent.title}"`);
  await notifyAllForNewsAndAgenda("Nieuw event in de agenda", agendaEvent.title || "Er is een nieuw event toegevoegd.");
});

/**
 * Datum als "YYYY-MM-DD" in de Amsterdamse tijdzone, zodat we dagen kunnen
 * vergelijken zonder dat UTC-vs-lokale-tijd voor een off-by-one zorgt.
 */
function dateKeyAmsterdam(date) {
  return new Intl.DateTimeFormat("en-CA", {timeZone: "Europe/Amsterdam"}).format(date);
}

// 5. Herinnering 4 dagen voor het einde van een challenge, alleen naar wie nog geen score heeft ingevuld
exports.remindChallengeDeadline = onSchedule(
    {schedule: "0 9 * * *", timeZone: "Europe/Amsterdam", region: "europe-west4"},
    async () => {
      const targetKey = dateKeyAmsterdam(new Date(Date.now() + 4 * 24 * 60 * 60 * 1000));

      const challengesSnapshot = await db.collection("challenges").get();
      const endingChallenges = challengesSnapshot.docs
          .map((doc) => ({id: doc.id, ...doc.data()}))
          .filter((challenge) => challenge.endDate && dateKeyAmsterdam(challenge.endDate.toDate()) === targetKey);

      if (endingChallenges.length === 0) {
        console.log(`[remindChallengeDeadline] Geen challenge die op ${targetKey} eindigt, niks gedaan.`);
        return;
      }

      const profilesSnapshot = await db.collection("user_profiles").get();
      const allUids = profilesSnapshot.docs.map((doc) => doc.id);

      for (const challenge of endingChallenges) {
        const resultsSnapshot = await db
            .collection("challenge_results")
            .where("challengeId", "==", challenge.id)
            .get();
        const submittedUids = new Set(resultsSnapshot.docs.map((doc) => doc.data().uid));

        const eligibleUids = allUids.filter((uid) => !submittedUids.has(uid));
        console.log(`[remindChallengeDeadline] "${challenge.title}" eindigt op ${targetKey}: ${eligibleUids.length}/${allUids.length} leden hebben nog geen score ingevuld.`);

        await Promise.all(eligibleUids.map((uid) => sendToUser(
            uid,
            "notifyChallengeReminders",
            "Nog 4 dagen voor de challenge!",
            `"${challenge.title}" sluit binnenkort — vul nog snel je score in!`,
            {type: "challenge", challengeId: challenge.id},
        )));
      }
    },
);

// Hoelang een Evenementen-album blijft staan vanaf de vroegste foto erin —
// hier aanpassen + opnieuw deployen is genoeg om de bewaartermijn te wijzigen.
const EVENT_ALBUM_RETENTION_MONTHS = 12;

/**
 * Haalt het opslagpad uit een Firebase Storage download-URL, zodat we het
 * bestand kunnen verwijderen zonder dat pad apart te hoeven bijhouden.
 */
function storagePathFromUrl(url) {
  const match = /\/o\/([^?]+)/.exec(url || "");
  return match ? decodeURIComponent(match[1]) : null;
}

// 6. Evenementen-albums ouder dan de bewaartermijn automatisch opruimen
exports.cleanupOldEventAlbums = onSchedule(
    {schedule: "0 3 * * *", timeZone: "Europe/Amsterdam", region: "europe-west4"},
    async () => {
      const cutoff = new Date();
      cutoff.setMonth(cutoff.getMonth() - EVENT_ALBUM_RETENTION_MONTHS);

      const snapshot = await db.collection("photo_posts").where("category", "==", "event").get();

      const albums = new Map();
      for (const doc of snapshot.docs) {
        const data = doc.data();
        const title = data.title || "";
        if (!albums.has(title)) albums.set(title, []);
        albums.get(title).push({id: doc.id, ...data});
      }

      let deletedAlbums = 0;
      let deletedPhotos = 0;

      for (const [title, posts] of albums) {
        const oldestCreatedAt = posts.reduce((min, post) => {
          const created = post.createdAt ? post.createdAt.toDate() : new Date();
          return created < min ? created : min;
        }, new Date());

        if (oldestCreatedAt >= cutoff) continue;

        console.log(`[cleanupOldEventAlbums] Album "${title}" is ouder dan ${EVENT_ALBUM_RETENTION_MONTHS} maanden (${posts.length} foto's), wordt verwijderd.`);

        await Promise.all(posts.map(async (post) => {
          await db.collection("photo_posts").doc(post.id).delete();
          const path = storagePathFromUrl(post.imageUrl);
          if (path) {
            await storage.bucket().file(path).delete().catch(() => {});
          }
        }));

        deletedAlbums++;
        deletedPhotos += posts.length;
      }

      console.log(`[cleanupOldEventAlbums] Klaar: ${deletedAlbums} album(s), ${deletedPhotos} foto('s) verwijderd.`);
    },
);