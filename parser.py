import sqlite3
import pandas as pd

def normalize_text(value):
    if pd.isna(value):
        return None
    s = str(value).strip()
    return None if s in {"","-","nan","NaN"} else s