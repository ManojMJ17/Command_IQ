# # src/our_package_name/predict.py
# import torch
# from transformers import T5Tokenizer, T5ForConditionalGeneration
# from pathlib import Path
# import re
# import subprocess

# # Paths
# BASE_DIR = Path(__file__).resolve().parent.parent
# TOKENIZER_PATH = BASE_DIR / "model" / "t5_base_tokenizer"
# MODEL_PATH = BASE_DIR / "model" / "saved_model" / "t5_base_model.pt"

# # Device
# DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# class CommandPredictor:
#     def __init__(self):
#         print("Loading model and tokenizer from local files...")
#         self.tokenizer = T5Tokenizer.from_pretrained(str(TOKENIZER_PATH))
#         self.model = T5ForConditionalGeneration.from_pretrained("t5-base")
#         # self.model = T5ForConditionalGeneration.from_pretrained(str(MODEL_PATH))
#         self.model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE, weights_only=True))
#         self.model.to(DEVICE)
#         self.model.eval()
#         print("Model and tokenizer loaded successfully!")

#     def normalize_query(self, query: str) -> str:
#         query = query.strip()
#         if len(query) > 0:
#             query = query[0].upper() + query[1:]
#         query = re.sub(r'\s+', ' ', query)
#         return query

#     def clean_command(self, cmd: str) -> str:
#         cmd = re.sub(r'find\.', 'find .', cmd)
#         cmd = re.sub(r'(?<=[a-zA-Z])\.(?=[a-zA-Z0-9])', '. ', cmd)
#         cmd = cmd.replace("-Rference", "--reference").replace(" -ld", " -l -d")
#         cmd = re.sub(r'\s+', ' ', cmd).strip()
#         return cmd

#     def predict(self, query: str) -> str:
#         normalized_query = self.normalize_query(query)
#         input_text = "translate: " + normalized_query
#         input_ids = self.tokenizer.encode(input_text, return_tensors="pt").to(DEVICE)
#         with torch.no_grad():
#             outputs = self.model.generate(input_ids, max_length=64, num_beams=4, early_stopping=True)
#         raw_command = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
#         return self.clean_command(raw_command)

#     def run_command(self, command: str):
#         run = input(f"Run this command? [y/n]: ").strip().lower()
#         if run == 'y':
#             try:
#                 print("\nExecuting command...\n")
#                 result = subprocess.run(command, shell=True, text=True, capture_output=True)
#                 print(result.stdout)
#                 if result.stderr:
#                     print("Errors:", result.stderr)
#             except Exception as e:
#                 print(f"Failed to execute command: {e}")
#         else:
#             print("Command not executed.")


# src/cli/predict.py
import torch
from transformers import T5Tokenizer, T5ForConditionalGeneration
from pathlib import Path
import re
import subprocess
import faiss
import pickle
import numpy as np
from sentence_transformers import SentenceTransformer
from collections import Counter

# --------------------------
# Paths
# --------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
TOKENIZER_PATH = BASE_DIR / "model" / "t5_base_tokenizer"
MODEL_PATH = BASE_DIR / "model" / "saved_model" / "t5_base_model.pt"
ARCH_PATH = BASE_DIR / "model" / "t5_base_arch"

FAISS_INDEX_PATH = BASE_DIR / "faiss_index" / "faiss_index_combined.index"
METADATA_PATH = BASE_DIR / "faiss_index" / "faiss_metadata_combined.pkl"
EMB_MODEL_PATH = BASE_DIR / "faiss_index" / "models" / "all-mpnet-base-v2"

# --------------------------
# Device
# --------------------------
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"


class CommandPredictor:
    def __init__(self):
        # Load T5
        print("Loading T5 model...")
        self.tokenizer = T5Tokenizer.from_pretrained(str(TOKENIZER_PATH))
        self.model = T5ForConditionalGeneration.from_pretrained(str(ARCH_PATH))
        self.model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE))
        self.model.to(DEVICE)
        self.model.eval()
        print("T5 model loaded.")

        # Load FAISS + embeddings
        print("Loading FAISS index...")
        self.index = faiss.read_index(str(FAISS_INDEX_PATH))
        with open(METADATA_PATH, "rb") as f:
            self.metadata = pickle.load(f)
        self.embed_model = SentenceTransformer(str(EMB_MODEL_PATH))
        print(f"FAISS index loaded with {len(self.metadata)} entries.")

    # --------------------------
    # Helpers
    # --------------------------
    def normalize_query(self, query: str) -> str:
        query = query.strip()
        if len(query) > 0:
            query = query[0].upper() + query[1:]
        query = re.sub(r"\s+", " ", query)
        return query

    def clean_command(self, cmd: str) -> str:
        cmd = re.sub(r"find\.", "find .", cmd)
        cmd = re.sub(r"(?<=[a-zA-Z])\.(?=[a-zA-Z0-9])", ". ", cmd)
        cmd = cmd.replace("-Rference", "--reference").replace(" -ld", " -l -d")
        cmd = re.sub(r"\s+", " ", cmd).strip()
        return cmd

    def faiss_search(self, query: str, top_k: int = 5):
        query_emb = self.embed_model.encode([query], convert_to_numpy=True)
        query_emb = query_emb / np.linalg.norm(query_emb, axis=1, keepdims=True)
        D, I = self.index.search(query_emb, top_k)
        return [self.metadata[i]["cmd"] for i in I[0]]

    def t5_predict(self, query: str) -> str:
        normalized_query = self.normalize_query(query)
        input_text = "translate: " + normalized_query
        input_ids = self.tokenizer.encode(input_text, return_tensors="pt").to(DEVICE)
        with torch.no_grad():
            outputs = self.model.generate(
                input_ids, max_length=64, num_beams=4, early_stopping=True
            )
        raw_command = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        return self.clean_command(raw_command)

    # --------------------------
    # Hybrid Prediction
    # --------------------------
    # def predict(self, query: str) -> str:
    #     # Get FAISS candidates
    #     faiss_candidates = self.faiss_search(query)
    #     faiss_cmd = Counter(faiss_candidates).most_common(1)[0][0]

    #     # Get T5 prediction
    #     t5_cmd = self.t5_predict(query)

    #     # Hybrid logic: prefer FAISS if it matches T5 or just use FAISS
    #     if faiss_cmd.strip() == t5_cmd.strip():
    #         final_cmd = faiss_cmd
    #     else:
    #         # fallback preference → FAISS first, then T5
    #         final_cmd = faiss_cmd if faiss_cmd else t5_cmd

    #     return final_cmd

    def predict(self, query: str) -> str:
        # Get FAISS candidates
        faiss_candidates = self.faiss_search(query)
        faiss_cmd = faiss_candidates[0] if faiss_candidates else ""

        # Get T5 prediction
        t5_cmd = self.t5_predict(query)

        # Hybrid logic:
        # If FAISS matches T5 closely (same command or very similar), keep FAISS
        # Otherwise, prefer T5
        if faiss_cmd.strip() == t5_cmd.strip() or self.is_similar(faiss_cmd, t5_cmd):
            final_cmd = faiss_cmd
        else:
            final_cmd = t5_cmd

        return final_cmd

    # Add a helper for basic similarity check
    def is_similar(self, cmd1: str, cmd2: str) -> bool:
        """
        Return True if commands are similar enough (heuristic: few word differences)
        """
        words1 = set(cmd1.strip().split())
        words2 = set(cmd2.strip().split())
        return len(words1 & words2) / max(len(words1), len(words2)) > 0.6

    # --------------------------
    # finish Hybrid Prediction
    # --------------------------
    def run_command(self, command: str):

        try:
            print("\nExecuting command...\n")
            result = subprocess.run(command, shell=True, text=True, capture_output=True)
            print(result.stdout)
            if result.stderr:
                print("Errors:", result.stderr)
        except Exception as e:
            print(f"Failed to execute command: {e}")


    def explain(self, cmd: str) -> str:
        # Very simple placeholder explanations
        if cmd.startswith("ls"):
            return "List files in directory"
        elif cmd.startswith("df"):
            return "Show disk space usage"
        elif cmd.startswith("ps"):
            return "Display running processes"
        elif cmd.startswith("top"):
            return "Show real-time system usage"
        elif cmd.startswith("cat"):
            return "Display file contents"
        elif cmd.startswith("grep"):
            return "Search text patterns"
        else:
            return "No explanation available yet."
