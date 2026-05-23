import pandas as pd
import re

print("1. Loading Kaggle datasets...")
# Let's use the third dataset as our primary brain food
df = pd.read_csv("financial_decision_with_target_dataset.csv")

print("2. Cleaning text and extracting categories...")
cleaned_sentences = []

for index, row in df.iterrows():
    # Extract our category and raw text
    category = str(row['financial_strategy']).strip().capitalize()
    raw_text = str(row['tweet_content']).strip()
    
    # We only want 'Budgeting', 'Saving', 'Investing', etc. (You can add 'Shopping' or map them later)
    if category == "Nan" or category == "":
        continue
        
    # CLEANING MAGIC: Remove all hashtags and the word "TrendingTopic"
    # This regex removes anything starting with '#' and stops at a space
    clean_text = re.sub(r'#\S+', '', raw_text)
    clean_text = clean_text.replace('TrendingTopic:', '').strip()
    
    # Remove any lingering quotation marks or double spaces
    clean_text = clean_text.replace('"', '').replace('  ', ' ')
    
    # Format it for our trainer
    cleaned_sentences.append(f"[{category}] {clean_text}\n")

print("3. Saving to financial_advice_dataset.txt...")
with open("financial_advice_dataset.txt", "w", encoding="utf-8") as f:
    f.writelines(cleaned_sentences)

print(f"✅ SUCCESS: {len(cleaned_sentences)} pristine sentences prepped for the AI!")