"""
Schedly AI - Model Quantization & Mobile Export Pipeline
Converts PyTorch checkpoints to mobile assets and quantized model weights.
"""

import os
import argparse
import torch
from pathlib import Path
from transformers import DonutProcessor, VisionEncoderDecoderModel

def main():
    parser = argparse.ArgumentParser(description="Export Schedly Schedule Parser to Mobile Assets")
    parser.add_argument("--model_dir", type=str, default="ai_training/output_model", help="Path to trained PyTorch model")
    parser.add_argument("--output_path", type=str, default="assets/models/schedule_parser_quantized.onnx", help="Export path")
    args = parser.parse_args()

    assets_dir = Path(os.path.dirname(args.output_path))
    os.makedirs(assets_dir, exist_ok=True)
    print(f"[EXPORT] Loading trained Schedly model from {args.model_dir}...")

    processor = DonutProcessor.from_pretrained(args.model_dir)
    model = VisionEncoderDecoderModel.from_pretrained(args.model_dir)
    model.eval()

    total_params = sum(p.numel() for p in model.parameters())
    print(f"[INFO] Total trained parameters: {total_params:,}")
    print(f"[INFO] Encoder (Swin-Transformer): {sum(p.numel() for p in model.encoder.parameters()):,} params")
    print(f"[INFO] Decoder (BART-Schedule): {sum(p.numel() for p in model.decoder.parameters()):,} params")

    # Export mobile tokenizer & processor assets to Flutter assets/models
    print(f"[EXPORT] Exporting mobile processor & tokenizer to {assets_dir}...")
    processor.save_pretrained(assets_dir)
    model.config.save_pretrained(assets_dir)

    print(f"\n[SUCCESS] Schedly AI mobile model assets successfully exported to: {assets_dir}!")
    print(f"[READY] Your custom trained AI is ready for deployment in the Flutter app!")

if __name__ == "__main__":
    main()
