# Art generation manifest

Generated with the built-in OpenAI image generation tool, then resized with
`prepare_assets.py`. Final artwork is PNG and contains no generated text.

## Shared style

> Flat 2D game illustration, soft hand-painted look, muted teal and warm paper
> palette, gentle ironic Soviet-office mood, clean dark-teal outlines, no text,
> letters, logos, watermark, border, or UI overlay.

## Portraits

Base prompt: a waist-up visual-novel portrait of Lyubov Genrikhovna, a stern but
quietly warm accountant aged 55–60, dark hair in a neat practical bun, glasses on
a fine chain, dark navy blazer, small white collar, soft diffuse office light,
transparent background. Straight-on three-quarter view with both shoulders,
hands, and waist visible. The neutral expression looks over the glasses as if to
say “Well then, what do you want?”

All variants used the neutral image as an identity reference and preserved the
woman, pose, head angle, hands, clothes, crop, palette, lighting, and silhouette.
Only the face and gaze changed:

- `lg_down.png`: lowered gaze, focused on papers or a calculator below frame.
- `lg_angry.png`: pressed lips, knitted brows, controlled office anger.
- `lg_happy.png`: bright eyes and a small genuine smile about 1C or tea.
- `lg_melt.png`: softened eyes, restrained almost-smile, very light blush.
- `lg_whisper.png`: sideways glance and a discreet conspiratorial whisper.

## Background

`backgrounds/accounting_office.png`: old municipal accounting office from the
visitor side. Worn desk and service window on the left, folders, beige CRT with
an abstract accounting interface, adding-machine calculator and paper tape,
lamp, glass hatch, filing cabinet, and wall clock. Important detail is confined
to the left third and outer edges; center and right are calm and low-contrast for
a translucent dialogue panel. No people or readable text.

## Inventory icons

Shared icon framing: one centered object group in a consistent three-quarter
tabletop view with generous transparent padding and a readable silhouette.

- `item_choc.png`: partially opened hazelnut chocolate bar and one hazelnut.
- `item_passport.png`: worn burgundy passport-like booklet, geometric emblem.
- `item_pass.png`: pale-teal blank office pass in a clear holder and lanyard.
- `item_mug_empty.png`: empty cream office mug, teal rim, tiny chip.
- `doc_2025.png`: neat complete income-certificate form, paperclip.
- `doc_2026.png`: similar form, amber corner tab, dotted incomplete section.
- `doc_stamped.png`: cream form with a prominent abstract blue circular stamp.
- `doc_copy.png`: grayscale skewed photocopy, visibly without a blue stamp.

## Ending illustrations

- `endings/ending_human.png`: Lyubov Genrikhovna discreetly eats chocolate at
  the counter while the departing visitor carries the issued certificate.
- `endings/ending_formal.png`: shut glass service window with a blank taped card
  reserved for the code-rendered “Перерыв” label.
- `endings/ending_bank_closed.png`: visitor holds a blue-stamped certificate in
  front of locked bank doors and a blank sign panel.
- `endings/ending_burnout.png`: empty office at blue dusk, one lamp on, clock
  hands exactly at 18:00 with tick marks and no numerals.

