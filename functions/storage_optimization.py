import io
import os

from firebase_admin import storage
from firebase_functions import options, storage_fn

# Import shared to ensure Firebase Admin is initialized before triggers run.
import shared  # noqa: F401


def _get_pil_image():
    from PIL import Image
    return Image


@storage_fn.on_object_finalized(
    max_instances=10,
    memory=options.MemoryOption.MB_512,
    timeout_sec=300
)
def optimize_profile_picture(event: storage_fn.CloudEvent[storage_fn.StorageObjectData]):
    """
    Automatically optimizes profile pictures when uploaded to Firebase Storage.
    Creates multiple sized variants:
    - thumbnail (150x150) - for list views
    - medium (400x400) - for profile views
    - large (800x800) - for full screen
    """
    data = event.data
    bucket_name = data.bucket
    file_path = data.name
    content_type = data.content_type

    print(f"Processing file: {file_path}")

    if not file_path or 'profile_pictures/' not in file_path:
        print(f"Skipping non-profile picture: {file_path}")
        return

    if not content_type or not content_type.startswith('image/'):
        print(f"Skipping non-image file: {file_path}")
        return

    if '_thumb' in file_path or '_medium' in file_path or '_large' in file_path:
        print(f"Skipping already optimized image: {file_path}")
        return

    try:
        Image = _get_pil_image()

        bucket = storage.bucket(bucket_name)
        blob = bucket.blob(file_path)

        image_bytes = blob.download_as_bytes()
        img = Image.open(io.BytesIO(image_bytes))

        if img.mode not in ('RGB', 'L'):
            img = img.convert('RGB')

        file_name = os.path.splitext(file_path)[0]

        sizes = {
            'thumb': (150, 150, 85),
            'medium': (400, 400, 90),
            'large': (800, 800, 92),
        }

        uploaded_variants = []

        for suffix, (width, height, quality) in sizes.items():
            img_copy = img.copy()
            img_copy.thumbnail((width, height), Image.Resampling.LANCZOS)

            output_buffer = io.BytesIO()
            img_copy.save(
                output_buffer,
                format='JPEG',
                quality=quality,
                optimize=True,
                progressive=True,
            )
            output_buffer.seek(0)

            optimized_path = f"{file_name}_{suffix}.jpg"
            optimized_blob = bucket.blob(optimized_path)
            optimized_blob.upload_from_file(
                output_buffer,
                content_type='image/jpeg'
            )
            optimized_blob.make_public()

            uploaded_variants.append({
                'size': suffix,
                'path': optimized_path,
                'url': optimized_blob.public_url,
                'dimensions': f"{img_copy.width}x{img_copy.height}"
            })

            print(f"Created {suffix} variant: {optimized_path} ({img_copy.width}x{img_copy.height})")

        print(f"✓ Successfully optimized profile picture: {file_path}")
        print(f"✓ Created {len(uploaded_variants)} variants")

    except Exception as e:
        print(f"❌ Error optimizing image {file_path}: {str(e)}")
