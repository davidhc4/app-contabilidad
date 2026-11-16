# Bolsillo — Privacy policy and terms

_Versión en español: [PRIVACIDAD.md](PRIVACIDAD.md)_

_Last updated: November 15, 2026_

Bolsillo is a free, open-source app for keeping track of your expenses. This
page explains, in plain words, what the app does with your information, which
permissions it uses, how to tell that your copy is the official one, and the
terms of use.

In one sentence: **your data stays on your phone.** The app has no accounts,
does not sign you up, shows no ads, and does not send your information to any
server.

## Who is responsible

The app is developed and maintained by **David (App developer)**,
independently.

## What information the app handles

Everything you create in the app (income, expenses, cards, categories, budget,
photos you choose for your cards, your profile name and photo) is stored
**only on your phone**, in a local database.

- It is not sent to any server.
- It is not shared with the developer or any third party.
- It is excluded from Android's automatic backups.
- If you uninstall the app, that information is deleted with it.

The app does **not** collect analytics, location, contacts, advertising
identifiers, or anything of the sort.

## Permissions the app uses and why

The app only asks for permissions when you use the feature that needs them, and
it works even if you don't grant them:

- **Internet**: only when you tap "Check for updates" in Settings. It is used
  to check for and download the new version from GitHub. None of your data is
  sent.
- **Install apps**: to open the Android installer with the update you
  downloaded.
- **Notifications**: for local reminders inside the app (for example, a card
  look you unlocked but haven't used). They come from the phone, not from any
  server.
- **Photos**: only if you pick a photo from your gallery to customize a card or
  your profile. The photo is copied to the app's private folder and never
  leaves your phone.

The app does **not** use location, camera, microphone, contacts, or SMS
reading.

## When information leaves your phone

Only in two cases, and always because you choose to:

- **Share a CSV backup**: you create the file and choose where to send it
  (email, Drive, WhatsApp, etc.).
- **Support with a donation**: it opens PayPal in your browser. The payment
  happens on PayPal's page; the app never sees or stores your card details.

## Minors

Learning to manage money is useful at any age, so the app is suitable for
everyone. Because the app asks for no personal data, creates no accounts, and
sends nothing to the internet (other than checking for updates), it does not
collect information from anyone, minor or adult. If a minor uses it, we
recommend an adult's guidance for anything involving handling money.

## How to tell your Bolsillo is the official one

Because the app is open source, anyone can read the code. That is good, but it
also means a bad actor could take the code, modify it, and publish a copy. So
you are not fooled:

- **Download the app only from the official repository:**
  `https://github.com/davidhc4/app-contabilidad` (the _Releases_ section).
- Every official version is **digitally signed** with a private key that only
  the developer has and that is never published.
- A copy made by someone else would have a different signature, and Android
  **will not accept it** as an update to the official app.

If you see "Bolsillo" somewhere other than that repository, it is not the
official version.

## Terms of use

- Bolsillo is free software under the [MIT](LICENSE) license. You may read,
  use, modify, and share the code.
- If you publish a modified version, do it with **your own different name and
  image**. The name "Bolsillo" and its identity (icon and design) belong to its
  author; do not use them to pass another app off as this one. The MIT license
  lets you use the code but asks you to keep the credit to the original author.
- The app is provided "as is", without warranties. Make your own backups (the
  "Share a CSV backup" option): the developer cannot recover lost data, because
  he never has it.
- The app is a tool to help you organize your money; it is not financial
  advice.

## Changes to this policy

If anything changes, this page and the date above will be updated. Previous
versions remain in the repository's history.

## Contact

Questions about privacy, or found a security problem? Write it in the official
repository:

- For questions or bugs: the **Issues** tab.
- For a security problem: the **Security → Report a vulnerability** tab (so it
  arrives privately).

`https://github.com/davidhc4/app-contabilidad`
