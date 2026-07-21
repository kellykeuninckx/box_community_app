const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Stuurt een melding naar één specifieke gebruiker, maar alleen als ze een
 * token hebben en de betreffende voorkeur niet hebben uitgezet.
 */
async function sendToUser(uid, preferenceField, title, body) {
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
    });
    console.log(`[sendToUser] Melding succesvol verstuurd naar uid ${uid}: "${title}"`);
  } catch (error) {
    console.error(`[sendToUser] Melding versturen naar ${uid} mislukt:`, error);
  }
}

/**
 * Stuurt een melding naar iedereen die de Nieuws & Agenda-voorkeur aan heeft staan.
 */
async function notifyAllForNewsAndAgenda(title, body) {
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
    });
    console.log(`[notifyAllForNewsAndAgenda] Verstuurd naar ${tokens.length} tokens: "${title}"`);
  } catch (error) {
    console.error("[notifyAllForNewsAndAgenda] Versturen mislukt:", error);
  }
}

// 1. Reactie (emoji) op een Wall of Fame-post
exports.onWallOfFameReaction = onDocumentUpdated("wall_of_fame_posts/{postId}", async (event) => {
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
  console.log(`[onNewsPostCreated] Nieuw bericht: "${post.title}"`);
  await notifyAllForNewsAndAgenda("Nieuw bericht", post.title || "Er staat een nieuw bericht klaar.");
});

// 4. Nieuw agenda-event
exports.onAgendaEventCreated = onDocumentCreated("agenda_events/{eventId}", async (event) => {
  const agendaEvent = event.data.data();
  console.log(`[onAgendaEventCreated] Nieuw event: "${agendaEvent.title}"`);
  await notifyAllForNewsAndAgenda("Nieuw event in de agenda", agendaEvent.title || "Er is een nieuw event toegevoegd.");
});