import joblib
import random
from collections import defaultdict

print("1. Loading categorized financial advice text...")
with open("financial_advice_dataset.txt", "r") as f:
    lines = f.readlines()

# Master dictionary holding a Bigram Markov chain for each category
multi_brain_model = {}
# Dictionary to store the first two words of every sentence to start generations
starters = defaultdict(list)

print("2. Training Domain-Specific Bigram Models...")
for line in lines:
    if not line.strip():
        continue
    parts = line.strip().split("] ", 1)
    if len(parts) < 2:
        continue
        
    category = parts[0].replace("[", "")
    sentence = parts[1]

    if category not in multi_brain_model:
        multi_brain_model[category] = defaultdict(list)

    words = sentence.split()
    if len(words) < 3:
        continue

    # Save the first two words as a valid starting point for this category
    starters[category].append((words[0], words[1]))

    # Train the Bigram (2-word memory)
    for i in range(len(words) - 2):
        current_state = (words[i], words[i + 1])
        next_word = words[i + 2]
        multi_brain_model[category][current_state].append(next_word)

print("3. Saving Multi-Brain Bigram Recommender...")
final_brain = {
    "chains": {k: dict(v) for k, v in multi_brain_model.items()},
    "starters": dict(starters)
}
joblib.dump(final_brain, "custom_recommender_model.pkl")
print("✅ SUCCESS: Bigram AI trained and saved!")