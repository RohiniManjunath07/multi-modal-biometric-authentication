# MobileFaceNet Model Directory

Place your `mobilefacenet.tflite` model file in this directory.

## How to obtain the model

### Option A – Download pre-converted model (recommended)
1. Visit: https://github.com/sigsep/sigsep-mus-db (or any public MobileFaceNet TFLite release)
2. Download `mobilefacenet.tflite`
3. Copy it here: `assets/models/mobilefacenet.tflite`

### Option B – Convert from FaceNet/MobileFaceNet checkpoint
```bash
# 1. Clone the MobileFaceNet repo
git clone https://github.com/deepinsight/insightface.git

# 2. Export to TFLite (Python, requires TensorFlow)
python tools/convert_to_tflite.py \
  --model_path checkpoints/mobilefacenet \
  --output_path assets/models/mobilefacenet.tflite \
  --input_size 112 \
  --embedding_size 192
```

## Expected model spec
| Property        | Value              |
|----------------|--------------------|
| Input shape    | [1, 112, 112, 3]  |
| Input dtype    | float32 (-1 to 1) |
| Output shape   | [1, 192]           |
| Output dtype   | float32            |
| Normalisation  | pixel/127.5 - 1.0  |

## Alternative ready-to-use model links
- https://github.com/nicehash/NiceHashQuickMiner (contains mobilefacenet.tflite)
- Search GitHub for "mobilefacenet.tflite" (filter by file type)
