# FitClub

FitClub is a Flutter application using Firebase Authentication and Cloud
Firestore.

## Admin subscription categories

The Admin > Abonnements screen stores each category in `abonnements`. Category
documents use `isCategory: true`, include four `formules` (1, 3, 6 and 12
months), and can include `horaires`, `description`, `imageAsset` and `imageUrl`.
The six default categories start with editable demonstration prices.

Defaults are initialized transactionally when the Abonnements screen loads.
The persistent registry at `configuration/subscriptionCategories` tracks
intentionally deleted default IDs so reopening the screen does not recreate
them. Missing defaults are repaired without replacing existing category
content. Existing single-duration subscription documents remain readable and
manageable. Members can select a configured duration; the selected months are
stored as `dureeAbonnementMois` on the member document. Older member records
continue using the duration on their referenced legacy subscription.

Selecting a device image uploads it to Firebase Storage at
`abonnements/{subscriptionId}/image`. The Firebase app options include a Storage
bucket, but Storage security rules must also be configured in Firebase to allow
authorized administrators to upload images. Configure and verify restrictive
admin-only rules before enabling uploads; no permissive rules are bundled with
the application.
