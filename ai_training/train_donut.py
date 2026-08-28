import os
import json
import argparse
from pathlib import Path
from PIL import Image

try:
    import torch
    from torch.utils.data import Dataset
    from transformers import (
        DonutProcessor,
        VisionEncoderDecoderModel,
        Seq2SeqTrainer,
        Seq2SeqTrainingArguments,
    )
except ImportError as e:
    torch = None

class ScheduleDataset(Dataset):
    def __init__(self, data_dir, processor, max_length=384):
        self.data_dir = Path(data_dir)
        self.images_dir = self.data_dir / "images"
        self.processor = processor
        self.max_length = max_length
        self.samples = []

        metadata_path = self.data_dir / "metadata.jsonl"
        if metadata_path.exists():
            with open(metadata_path, "r", encoding="utf-8") as f:
                for line in f:
                    if line.strip():
                        self.samples.append(json.loads(line))

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        sample = self.samples[idx]
        image_path = self.images_dir / sample["file_name"]
        image = Image.open(image_path).convert("RGB")
        image = image.resize((480, 640))

        # Encode image into lightweight Donut input format
        pixel_values = self.processor(image, return_tensors="pt").pixel_values.squeeze(0)

        # Ground truth schedule JSON string
        target_text = sample["ground_truth"]
        labels = self.processor.tokenizer(
            target_text,
            add_special_tokens=False,
            max_length=self.max_length,
            padding="max_length",
            truncation=True,
            return_tensors="pt",
        ).input_ids.squeeze(0)

        labels[labels == self.processor.tokenizer.pad_token_id] = -100

        return {"pixel_values": pixel_values, "labels": labels}

def collate_fn(batch):
    pixel_values = torch.stack([item["pixel_values"] for item in batch])
    labels = torch.stack([item["labels"] for item in batch])
    return {"pixel_values": pixel_values, "labels": labels}

def main():
    if torch is None:
        print("[ERROR] Cannot start training because PyTorch and HuggingFace dependencies are not installed.")
        print("[FIX] Run this command in your PowerShell terminal first:")
        print("      pip install torch torchvision transformers datasets sentencepiece pillow")
        return

    parser = argparse.ArgumentParser(description="Train Reminda Donut Document Transformer")
    parser.add_argument("--data_dir", type=str, default="ai_training/dataset", help="Path to dataset directory")
    parser.add_argument("--model_name", type=str, default="naver-clova-ix/donut-base", help="Pretrained Donut model")
    parser.add_argument("--output_dir", type=str, default="ai_training/output_model", help="Directory to save model")
    parser.add_argument("--epochs", type=int, default=5, help="Number of training epochs")
    parser.add_argument("--batch_size", type=int, default=1, help="Per device batch size")
    parser.add_argument("--learning_rate", type=float, default=3e-5, help="Learning rate")
    args = parser.parse_args()

    print(f"[INFO] Initializing Schedly Donut training on {args.data_dir}...")
    is_cuda = torch.cuda.is_available()
    print(f"[INFO] Device available: {'CUDA (GPU)' if is_cuda else 'CPU'}")

    # 1. Load Processor & Model (with lightweight resolution for CPU efficiency)
    print(f"[INFO] Downloading / loading base model: {args.model_name}...")
    processor = DonutProcessor.from_pretrained(
        args.model_name,
        size={"height": 640, "width": 480},
    )
    model = VisionEncoderDecoderModel.from_pretrained(args.model_name)

    # 2. Add special tokens for schedule parsing
    new_special_tokens = ["<s_schedules>", "</s_schedules>", "<s_entry>", "</s_entry>"]
    processor.tokenizer.add_special_tokens({"additional_special_tokens": new_special_tokens})
    model.decoder.resize_token_embeddings(len(processor.tokenizer))

    # 3. Configure generation tokens
    model.config.decoder_start_token_id = processor.tokenizer.bos_token_id
    model.config.pad_token_id = processor.tokenizer.pad_token_id
    model.config.vocab_size = len(processor.tokenizer)
    model.config.decoder.decoder_start_token_id = processor.tokenizer.bos_token_id
    model.config.decoder.pad_token_id = processor.tokenizer.pad_token_id
    model.config.decoder.vocab_size = len(processor.tokenizer)

    # 4. Prepare Dataset
    print(f"[INFO] Loading schedule dataset from {args.data_dir}...")
    train_dataset = ScheduleDataset(args.data_dir, processor)
    print(f"[INFO] Dataset loaded with {len(train_dataset)} schedule samples.")

    # 5. Training Arguments (optimized for stable memory usage)
    training_args = Seq2SeqTrainingArguments(
        output_dir=args.output_dir,
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        gradient_accumulation_steps=2,
        learning_rate=args.learning_rate,
        weight_decay=0.01,
        logging_steps=5,
        save_strategy="epoch",
        fp16=is_cuda,
        predict_with_generate=False,
        remove_unused_columns=False,
        dataloader_pin_memory=False,
        report_to="none",
    )

    # 6. Initialize Trainer
    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        data_collator=collate_fn,
    )

    print(f"[INFO] Starting model fine-tuning ({args.epochs} epochs)...")
    try:
        trainer.train()

        # 7. Save Final Model & Processor
        os.makedirs(args.output_dir, exist_ok=True)
        model.save_pretrained(args.output_dir)
        processor.save_pretrained(args.output_dir)
        print(f"\n[SUCCESS] Model training complete! Saved model to: {args.output_dir}")
        print(f"[NEXT STEP] Run: python ai_training/export_model.py to export to mobile format.")
    except Exception as e:
        import traceback
        print(f"\n[ERROR] Training encountered an exception: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    main()
