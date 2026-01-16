/**
 * Webhook Handler Cloud Functions
 *
 * Handles incoming webhooks from external services (Lob, SmartCredit).
 * Implements signature verification and event processing.
 */
import * as functions from "firebase-functions";
export declare const LOB_EVENT_TYPES: {
    readonly "letter.created": "Letter created";
    readonly "letter.rendered_pdf": "Letter PDF rendered";
    readonly "letter.rendered_thumbnails": "Letter thumbnails rendered";
    readonly "letter.deleted": "Letter deleted";
    readonly "letter.delivered": "Letter delivered";
    readonly "letter.failed": "Letter failed";
    readonly "letter.re-routed": "Letter re-routed";
    readonly "letter.returned_to_sender": "Letter returned to sender";
    readonly "letter.certified.mailed": "Certified letter mailed";
    readonly "letter.certified.in_transit": "Certified letter in transit";
    readonly "letter.certified.in_local_area": "Certified letter in local area";
    readonly "letter.certified.processed_for_delivery": "Certified letter processed for delivery";
    readonly "letter.certified.re-routed": "Certified letter re-routed";
    readonly "letter.certified.returned_to_sender": "Certified letter returned to sender";
    readonly "letter.certified.delivered": "Certified letter delivered";
    readonly "letter.certified.pickup_available": "Certified letter pickup available";
    readonly "letter.certified.issue": "Certified letter issue";
};
export declare const webhooksLob: functions.HttpsFunction;
export declare const webhooksSmartCredit: functions.HttpsFunction;
export declare const webhooksRetry: functions.HttpsFunction & functions.Runnable<any>;
export declare const webhooksList: functions.HttpsFunction & functions.Runnable<any>;
//# sourceMappingURL=index.d.ts.map