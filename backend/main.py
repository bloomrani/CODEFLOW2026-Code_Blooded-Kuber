import re
from fastapi import FastAPI, UploadFile, File, HTTPException
import pandas as pd
import joblib
import io
import random

app = FastAPI(title="CodeFlow AI Double-Model Analyzer")

# --- Load BOTH of your custom-trained offline AI models ---
classifier = joblib.load('bank_transaction_classifier.pkl')
recommender_brain = joblib.load('custom_recommender_model.pkl')

def generate_ai_recommendation(highest_spending_category: str, net_savings: float, max_words=15) -> str:
    """
    Dual-domain Bigram Markov Chain text generator mapped to Kaggle datasets.
    Blends ML-generated insights into a clean, human-like layout template.
    """
    chains = recommender_brain.get("chains", {})
    starters = recommender_brain.get("starters", {})

    # Helper function to run the Markov chain for any specific domain
    def generate_sentence(target_domain):
        category_chain = chains.get(target_domain)
        category_starters = starters.get(target_domain)

        if not category_chain or not category_starters:
            return ""

        current_state = random.choice(category_starters)
        generated_sentence = [current_state[0], current_state[1]]

        for _ in range(max_words):
            possible_next_words = category_chain.get(current_state, [])
            if not possible_next_words:
                break
                
            next_word = random.choice(possible_next_words)
            generated_sentence.append(next_word)
            current_state = (current_state[1], next_word)

        raw_text = " ".join(generated_sentence).strip()
        if not raw_text.endswith('.'):
            raw_text += '.'
        return raw_text

    # --- 1. Generate Raw Component Advice Streams ---
    if highest_spending_category in ['Grocery', 'Shopping', 'Food']:
        spending_domain = "Budgeting"
    else:
        spending_domain = "Saving"
        
    spending_advice = generate_sentence(spending_domain)
    
    investing_advice = ""
    if net_savings > 0:
        investing_advice = generate_sentence("Investing")

    # --- 2. Clean and Filter Raw Dataset Artifacts ---
    def clean_text(text):
        if not text:
            return ""
        
        # Fix encoding anomalies from Kaggle smart quotes
        text = text.replace('â€™', "'").replace('â€œ', '"').replace('â€', '"').replace('’', "'")
        
        # Hard-strip explicit Kaggle phrase tags out completely
        bad_phrases = [
            "Budgeting, Goal: Education Fund.", "Budgeting, Goal: Buying a House.",
            "Budgeting, Goal: Emergency Fund.", "Budgeting, Goal: Retirement Savings.",
            "Investing, Goal: Education Fund.", "Investing, Goal: Buying a House.",
            "Investing, Goal: Emergency Fund.", "Investing, Goal: Retirement Savings.",
            "Saving, Goal: Education Fund.", "Saving, Goal: Buying a House.",
            "Saving, Goal: Emergency Fund.", "Saving, Goal: Retirement Savings."
        ]
        for phrase in bad_phrases:
            text = text.replace(phrase, "")

        # PRONOUN ADAPTER: Convert first-person tweets into professional second-person advice
        pronoun_map = {
            r"\bi'm\b": "you're", r"\bi’m\b": "you're", r"\bi am\b": "you are",
            r"\bi\b": "you", r"\bme\b": "you", r"\bmy\b": "your", r"\bmyself\b": "yourself"
        }
        for pattern, replacement in pronoun_map.items():
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)
            
        return text.strip()

    clean_spend = clean_text(spending_advice)
    clean_invest = clean_text(investing_advice)

    # --- 3. The Conversational Compositor Engine ---
    if clean_spend and clean_invest:
        final_payload = (
            f"Based on your statement, your highest spending volume concentrated in your {highest_spending_category} sector. "
            f"To manage this pattern, remember that {clean_spend.lower()} On the other hand, since you maintained a solid surplus "
            f"of ₹{net_savings:,.0f} this month, it's a great opportunity to look forward: {clean_invest.lower()}"
        )
    elif clean_spend and net_savings <= 0:
        final_payload = (
            f"Your financial statement shows heavy activity in the {highest_spending_category} sector, resulting in a deficit this month. "
            f"Focus on structured adjustments: {clean_spend.lower()} Reducing non-essential expenses will help secure your capital stability."
        )
    else:
        final_payload = (
            f"Your financial statement shows high activity in {highest_spending_category}. "
            f"Track your spending closely to optimize your budget and increase your net savings."
        )

    # Clean up double punctuation points, capitalization, or awkward spacing errors
    final_payload = final_payload.replace('..', '.').replace(' .', '.').replace('  ', ' ')
    
    # Capitalize the first letter of sentences cleanly
    sentences = final_payload.split('. ')
    capitalized_sentences = [s.strip().capitalize() for s in sentences if s.strip()]
    final_payload = ". ".join(capitalized_sentences)
    if final_payload and not final_payload.endswith('.'):
        final_payload += '.'
        
    return final_payload


@app.post("/analyze")
async def analyze_statement(file: UploadFile = File(...)):
    try:
        if not file.filename.endswith('.csv'):
            raise HTTPException(status_code=400, detail="Invalid file type.")
            
        contents = await file.read()
        df = pd.read_csv(io.BytesIO(contents))
        df.columns = [col.strip().capitalize() for col in df.columns]
        
        # 🚨 THE CRITICAL FIX: Instantly convert any empty cells to 0 so Pandas math doesn't break
        df = df.fillna(0)
        
        # Model 1: Predict transaction categories
        df['Predicted_Category'] = classifier.predict(df['Narration'])
        def keyword_override(row):
            narration = str(row['Narration']).upper()
            if any(k in narration for k in ['ZOMATO', 'SWIGGY', 'RESTAURANT', 'DINNER', 'FOOD']):
                return 'Food'
            if any(k in narration for k in ['AMAZON', 'MYNTRA', 'FLIPKART', 'ZUDIO', 'SHOPPING', 'APPARELS']):
                return 'Shopping'
            if any(k in narration for k in ['APOLLO', 'PHARMACY', 'PHARMEASY', 'MEDICINES', 'HOSPITAL', 'CLINIC', '1MG', 'PRACTO']):
                return 'Healthcare'
            if any(k in narration for k in ['NETFLIX', 'SPOTIFY', 'BOOKMYSHOW', 'CONCERT', 'MOVIES', 'CINEMAS', 'MAKEMYTRIP', 'FLIGHT']):
                return 'Entertainment'
            if any(k in narration for k in ['BESCOM', 'ELECTRICITY', 'FIBER', 'JIO', 'AIRTEL', 'GAS', 'INDANE', 'WATER', 'RENT', 'MAINTENANCE']):
                return 'Utilities'
            # If no obvious keywords match, trust the trained machine learning model
            return row['Predicted_Category']
        df['Predicted_Category'] = df.apply(keyword_override, axis=1)
        
        # Financial math for metrics
        total_expense = float(df['Debit'].sum())
        total_income = float(df['Credit'].sum())
        
        # Calculate category totals safely
        debit_df = df[df['Debit'] > 0]
        if not debit_df.empty:
            category_totals = debit_df.groupby('Predicted_Category')['Debit'].sum().to_dict()
            highest_category = max(category_totals, key=category_totals.get)
        else:
            category_totals = {}
            highest_category = "Other"

        # Model 2: Generate text using your trained generative recommender model
        custom_ai_text = generate_ai_recommendation(highest_category, total_income - total_expense)

        # 🚨 THE JSON FIX: Ensure absolutely no 'NaN' floats slip through the loop
        clean_transactions = []
        for _, row in df.iterrows():
            clean_transactions.append({
                "date": str(row.get('Date', 'Unknown')),
                "narration": str(row.get('Narration', 'Unknown')),
                "debit": 0.0 if pd.isna(row.get('Debit')) else float(row.get('Debit')),
                "credit": 0.0 if pd.isna(row.get('Credit')) else float(row.get('Credit')),
                "balance": 0.0 if pd.isna(row.get('Balance')) else float(row.get('Balance')),
                "category": str(row.get('Predicted_Category', 'Other'))
            })

        return {
            "status": "success",
            "metrics": {
                "total_income": total_income,
                "total_expense": total_expense,
                "net_savings": total_income - total_expense,
                "highest_spending_category": highest_category
            },
            "category_breakdown": {k: float(v) for k, v in category_totals.items()},
            "transactions": clean_transactions,
            "ai_recommendation": custom_ai_text
        }
        
    except Exception as e:
        import traceback
        print("\n❌ CRITICAL CRASH LOG:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))