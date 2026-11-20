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

## Patient Not Found

Generated on 20 November 2026 with the built-in OpenAI image generation tool. The portrait atlas is RGBA, 1895×830 pixels. The clinic background and four ending images are RGB, 1672×941 pixels. The generated PNG files are kept in the project at their original dimensions.

| File | Content |
| --- | --- |
| `portraits/patient_cast.png` | Nika, Marina Petrovna, Mr Triton, duty doctor, in left-to-right order |
| `backgrounds/patient_clinic.png` | Reception hall with ten inspection objects |
| `endings/ending_patient_human.png` | The doctor examines Nika's throat |
| `endings/ending_patient_formal.png` | An official receipt is handed through the registration window |
| `endings/ending_patient_late.png` | Nika holds a ticket outside a closed consulting room |
| `endings/ending_patient_burnout.png` | Registration closes its blind before Nika receives a referral |

The four portrait regions are `(0, 0, 480, 830)`, `(480, 0, 464, 830)`, `(944, 0, 478, 830)` and `(1422, 0, 473, 830)`. Ending scenes use the atlas as an identity reference and the clinic background as a location/style reference.

### Cast prompt

```text
Use case: illustration-story. Asset type: one production-ready transparent PNG waist-up character atlas for the fictional bureaucratic clinic game Patient Not Found. Create ONE horizontal image with exactly FOUR DISTINCT adult characters in ONE ROW, evenly spaced in four equal vertical cells, target 2048 by 896 pixels. Each complete waist-up figure centered inside its own cell, both shoulders and hands visible, generous transparent margins so hair, elbows and hands never cross cell boundaries. Consistent scale and eye level. No dividing lines. Transparent alpha background. Character1 far left Nika: unmistakably an adult woman around25yearsold, human female with natural feline ears on her head and one softly curled cat tail visible beside her ordinary outfit. Pale warm skin, dark chestnut shoulder-length hair, amber eyes, ordinary muted lavender knitted sweater, loose darkteal casual jacket and simple soft scarf for her sore throat. Modest practical clothing. She is ill with fever but selfpossessed, tired eyes and a dry ironic raised brow, holding her own thermometer and a folded tissue, standing upright as an autonomous adult who speaks for herself. Character2 registrar Marina Petrovna: human woman around58yearsold, practical graybrown bun, thin reading glasses, darkteal office cardigan over a cream blouse, blank staff lanyard, holding a plain form and pen, weary professional expression beginning to soften, a recognizably ordinary publicclinic worker. Character3 Mr Triton: an intelligent adult male human-amphibian hybrid with a dignified broad olive-teal face, expressive humanlike eyes, subtle rounded gill frills and webbed fingers, wearing a worn charcoal jacket and a muted cream scarf, holding a very old queue slip, seated waist-up with patiently ironic expression. Character4 far right the duty doctor: human man around45yearsold, short darkhair with a little gray, creamwhite clinic coat over tealscrubs, stethoscope, holding a tongue depressor in a small clinical gesture, attentive matteroffact expression. Style: polished semi-realistic soft handpainted2D game illustration, gently textured brushwork and clean darkteal outlines, mutedteal and warm paper palette with restrained purple accents, soft diffuse light, gentle ironic everyday office atmosphere. Four different people and silhouettes, faces easy to read at small display size. No printed lettering or numbers, no names, no logos or watermarks, no UI, no badges with text, no environment. Do not add sexualized clothing, pet poses, collars, suggestive expression or childlike features. Nika is an adult patient with agency.
```

### Clinic prompt

```text
Use case: illustration-story. Asset type: wide16:9 background for a point-and-click fictional districtclinic in year2044, target1280x720pixels. View from visitor side into an empty worn but caredfor publicclinic reception and waitingroom. Soft semi-realistic handpainted2D game illustration, muted teal walls, warm paper cream counter and paintedwood, darkteal outlines, restrained purple accent. Soft office daylight. No people. Registration glass at left and center, queue seating toward right, ordinary municipal furnishings with one slightly futuristic terminal. Compose TEN separated clearly readable interactable objects, all primarily in the middle-height band below the top header and above the bottom quarter of the image. Keep center/right negative space calm enough for later dialogue overlays. Ten objects:1 desktop monitor on leftcounter,2 thick stack of paper forms nearby but separate,3 blank framed queue notice on leftwall,4 a distinct yellow sticky note on monitor side,5 an electronic queue display near upperleftwall with empty dark display and only abstract light bars,6 large healthy ficus by the far right wall,7 a recognizable metal stapler on counter,8 round wall clock at upperright with plain tickmarks and hands but no numerals,9 a low filing drawer cabinet with three differently colored blank folders protruding,10 a large publichealth poster on rightwall with blank title panel and soft abstract shapes. Every object has a separate visible silhouette and some empty space between it and neighbors. Put the counter objects around lower-middleheight so they are visible above the lower UI. No printed words, letters, numbers, logos, seals, watermarks or interface. No text on screens or paper. No humans or animals. Credible quiet clinic for a humane bureaucratic comedy.
```

### Ending prompts

Each ending combines this shared prompt with its scene below.

```text
Use case: illustration-story. Create one new landscape ending illustration for the fictional clinic game Patient Not Found. Target960x540pixels, cinematic16:9, one scene without panels. Input image1 is the identity reference atlas. Preserve Nika as the adult25yearold woman at farleft: chestnut wavy shoulderlengthhair, naturalbrowncatears, amberhumanlikeeyes, tealcasualjacket over modestlavendersweater, creamwoolscarf and cattail. She is a selfpossessed adultpatient with own agency. Preserve registrar Marina as the graybrownbun woman withreadingglasses and tealcardigan, and the doctor as the darkhairedmiddleagedman in creamwhitecoat overtealscrubs at farright. Inputimage2 is the clinic location/style reference. Render a polished semirealistic soft handpainted2D game illustration with gentle brushtexture, mutedteal and warmpaper palette, restrainedpurple accents, softdiffusecliniclight. Faces and hands readable, ordinary dignified people. No printedtext, letters, numerals, signagewords, logos, watermark or gameinterface. Every document and sign is blank except abstractlines. Nika remains clearlyadult and normallydressed.
```

**human**

```text
Scene: inside the duty doctor's modest examroom, Nika sits upright at the examchair with a slight relieved tired expression and mouth gently open. The doctor attentively checks her sore throat with a small light and tongue depressor in a normal medical examination. His blank paper patientcard lies on a desk. Nika is treated as an ordinary patient, an everyday act of practical care. Warm gentle desk light, restrained greenish daylight, reassuring intimate humane atmosphere. Only Nika and the doctor.
```

**formal**

```text
Scene: at the clinic registrationglass, Marina hands a single official blank receipt to Nika through the counter hatch. Nika holds the paper in one hand, tissue in the other, her expression dryly incredulous and exhausted, still visibly ill. The paperwork has been accepted while medicalcare waits. Thick stacks of paper and a darkmonitor are behind glass, muted cool daylight and a slight purple accent. Only adultNika and Marina.
```

**late**

```text
Scene: Nika stands in the clinic corridor holding a perfectly neat blank appointmentticket in her hand and looking at the CLOSED duty doctor's door. A blank rectangular sign on the door and an empty doctor'schair visible through frostedglass establish that the doctor has left. She is tired, disappointed and upright, withher own thoughtfulexpression, smallcat-tail relaxed besidehercoat. Cool late-morninglight, quiet emptycorridor, mutedteal and violetshadows. Nika alone.
```

**burnout**

```text
Scene: the clinic registrationglass is being closed with a plain opaque blind from inside. Nika stands outside the closing servicewindow with a small crumpled blank queue receipt and her scarf pulled close, facing the now unavailable window. Marina is only partlyvisible beyond theglass while shutting the blind, tired and constrained ratherthanmenacing. An emptywaitingarea and a turnedaway blank queue display emphasize a visit that was not recorded. Quiet cold cliniclight, subduedpurple and teal, humane melancholy. No readabletext.
```

The burnout scene received one final correction with the built-in editing tool so the doctor has already left.

```text
Use case: precise-object-edit. Edit this clinic illustration with one local correction. Remove the male doctor who is standing beside the ficus at the far right. Reconstruct the empty wall, remaining purple waitingchairs, ficus leaves and floor behind his former position so this corner is an empty clinic waiting area. Keep Nika's face, adult identity, cat ears, tail, clothing, scarf, tissue, exact pose, and position unchanged. Keep Marina behind the registration glass closing the blind unchanged. Preserve all other parts, painting style, proportions, colors, lighting, image dimensions and blank signs. No additional people. No text, letters, numbers, logos, watermark or user interface. The scene is the registration desk closing after the doctor has already left.
```
