# Art generation manifest

Generated with the built-in OpenAI image generation tool. The accounting artwork
was resized with `prepare_assets.py`. The school teacher atlas retains its generated
PNG and alpha channel. Final artwork contains no generated text.

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

## School teacher atlas

Generated on 18 November 2026 with the built-in image generation tool.
File `portraits/school_teachers.png` is RGBA, 1983×793 pixels, with a transparent background.
Teachers run from left to right in lesson order. The generated spacing varies slightly,
so the consuming AtlasTexture regions follow the transparent gaps.

| Teacher | Source x | Source width | Source y and height |
| --- | --- | --- | --- |
| Mathematics | 0 | 417 | 0, 793 |
| Russian language | 417 | 377 | 0, 793 |
| Physics | 794 | 383 | 0, 793 |
| History | 1177 | 393 | 0, 793 |
| Physical education | 1570 | 413 | 0, 793 |

The final generation prompt follows.

```text
Use case: illustration-story. Asset type: one production-ready transparent PNG character atlas for a Russian school satire game. Create ONE wide horizontal image containing exactly FIVE DISTINCT fictional adult school teachers, each in a separate equally sized vertical cell, in ONE ROW. Target canvas 2560 x 1024. The five cells each occupy exactly one fifth of the image width. No visible dividing lines. Full waist-up portraits, complete heads and hands, identical scale, each centered inside its cell with generous clear transparent margins. All people fully contained in their own cell without overlaps. Frontal three-quarter stance, looking toward the player. Consistent polished semi-realistic hand-painted 2D game illustration, soft brush textures, restrained dark-teal outlines, muted teal/navy clothes and warm paper/ochre accents, soft even office light. Gentle ironic everyday school mood. Character 1, at far left: woman mathematics teacher about 55 with short dark wavy hair, small reading glasses, teal cardigan, tired strict raised eyebrow, holding a blank exercise sheet and a red pen. Character 2: woman Russian language teacher about 40, auburn bob haircut, warm ochre blouse and navy vest, dry amused half-smile, holding a closed plain notebook. Character 3: male physics teacher about 60, thin face, sparse gray hair, round glasses, slightly rumpled teal jacket over cream shirt, curious raised brow, holding an unmarked wooden ruler. Character 4: male history teacher about 50, dark mustache and graying temples, beige jacket, navy turtleneck, measured knowing expression, one hand making a small explanatory gesture, holding an old plain book. Character 5, at far right: physical education teacher man about 40, athletic build, short sandy hair, teal tracksuit without branding, whistle on a cord, energetic encouraging expression, holding a plain stopwatch without numbers. These are five different people, with clearly distinct silhouettes and expressive faces visible at small display sizes. Actual transparent alpha background across the entire canvas around each cutout. No environment, no chalkboard. No lettering, no numbers, no names, no logos, no watermarks, no decorative borders, no user interface.
```

## Sunny school window

Generated on 19 November 2026 with the built-in OpenAI image generation tool.
File `backgrounds/school_sunny_window.png` is RGB, 1672×941 pixels. The author requested a photorealistic sunny view for intermissions. The generated PNG is used with an aspect-preserving crop.

The final generation prompt follows.

```text
Use case: photorealistic-natural. Asset type: landscape background photograph for a quiet intermission in a school game, wide 16:9 composition, target 1600 by 900 pixels. A beautiful peaceful sunny daytime view through a large clean school corridor window, photographed at a student's eye level from inside the corridor looking out. The wide window has slim off-white painted frames and a simple deep pale wooden windowsill. A little warm cream-colored interior wall is visible at the sides. Outdoors there is a welcoming green school courtyard with mature leafy trees, softly sunlit grass and a simple winding path. Rich but natural spring-green foliage, clear blue sky with a few small soft clouds. Warm late-morning sunlight enters through the window and makes gentle leaf shadows across the sill. Open airy feeling, the calm pleasure of looking outside during a break. Convincing professional architectural lifestyle photography, realistic glass reflections kept subtle, natural lens perspective, soft depth, fine natural materials and textures, restrained exposure, crisp foliage and real sunlight. The outside view occupies most of the image, balanced light and shadows, no harsh overexposure. No people, no faces, no children, no pets, no lettering, no numbers, no signs, no logos, no watermark, no game interface, no illustration, no cartoon, no drawn doodles, no artificial filter, no fantasy elements.
```
