# import argparse, json
# import numpy as np
# import librosa

# def analyze_music():
#     return {
#     }

# analyzer/analyze.py
#!/usr/bin/env python3
import argparse, json
import librosa, numpy as np

def load_wav(path):
    y, sr = librosa.load(path, sr=None, mono=True)
    return y, sr

