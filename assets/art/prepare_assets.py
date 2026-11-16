from pathlib import Path
from PIL import Image


def fit_transparent(source: Path, destination: Path, size: tuple[int, int]) -> None:
    image = Image.open(source).convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha and red > 210 and green < 55 and blue < 55:
                pixels[x, y] = (red, green, blue, 0)
    image.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    offset = ((size[0] - image.width) // 2, size[1] - image.height)
    canvas.alpha_composite(image, offset)
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination, "PNG", optimize=True)


def fit_cover(source: Path, destination: Path, size: tuple[int, int]) -> None:
    image = Image.open(source).convert("RGB")
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    destination.parent.mkdir(parents=True, exist_ok=True)
    resized.crop((left, top, left + size[0], top + size[1])).save(
        destination, "PNG", optimize=True
    )


if __name__ == "__main__":
    raise SystemExit("Import this helper from the asset preparation command.")
