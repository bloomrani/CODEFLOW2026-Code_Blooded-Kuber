import re
from fastapi import FastAPI, UploadFile, File, HTTPException
import pandas as pd
import joblib
import io
import random
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="CodeFlow AI Double-Model Analyzer")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows any origin (including localhost)
    allow_credentials=True,
    allow_methods=["*"],  # Allows POST, GET, etc.
    allow_headers=["*"],  # Allows your custom ngrok headers
)

# --- Load BOTH of your custom-trained offline AI models ---
classifier = joblib.load('bank_transaction_classifier.pkl')
recommender_brain = joblib.load('custom_recommender_model.pkl')

def generate_ai_recommendation(highest_spending_category: str, net_savings: float, max_words=20) -> str:
    chains = recommender_brain.get("chains", {})
    starters = recommender_brain.get("starters", {})

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
        return raw_text if raw_text.endswith('.') else raw_text + '.'

    # 1. Get advice explicitly for the highest category
    target_category = str(highest_spending_category).capitalize()
    spending_advice = generate_sentence(target_category)
    
    # 2. Get forward-looking advice if they made a profit
    investing_advice = ""
    if net_savings > 0:
        investing_advice = generate_sentence("Investing")

    # 3. Clean and Compose the Final Insight (Empathetic Engine)
    if target_category == "Healthcare":
        if net_savings <= 0:
            final_payload = (
                f"Sudden medical and health priorities created an exceptional deficit of ₹{abs(net_savings):,.2f} this month. "
                f"Recovery Insight: {spending_advice} "
                f"Prioritizing your physical recovery takes precedence, while building back an emergency cash buffer can stabilize your upcoming cycles."
            )
        else:
            final_payload = (
                f"Your statement reflects significant medical outlays this cycle. "
                f"Recommendation: {spending_advice} "
                f"Since you still maintained a net surplus of ₹{net_savings:,.2f}, your baseline financial framework remains highly resilient."
            )
    elif spending_advice and investing_advice:
        final_payload = (
            f"Your primary expenditure this cycle was concentrated in {target_category}. "
            f"Strategy: {spending_advice} "
            f"Since you secured a net surplus of ₹{net_savings:,.2f}, consider your next move: {investing_advice}"
        )
    elif spending_advice and net_savings <= 0:
        final_payload = (
            f"Heavy activity in {target_category} led to a financial deficit this cycle. "
            f"Correction Strategy: {spending_advice} "
            f"Reducing outlays here is critical to restoring your capital baseline."
        )
    else:
        final_payload = f"Track your {target_category} spending closely to optimize your net savings."

    # Clean up any weird spacing
    return final_payload.replace('  ', ' ').strip()


@app.post("/analyze")
async def analyze_statement(file: UploadFile = File(...)):
    try:
        if not file.filename.endswith('.csv'):
            raise HTTPException(status_code=400, detail="Invalid file type.")
            
        contents = await file.read()
        df = pd.read_csv(io.BytesIO(contents))
        
        # Standardize initial column strings to Title Case to make matching easier
        df.columns = [col.strip().capitalize() for col in df.columns]
        
        # 🌟 THE BANK-AGNOSTIC FIX: Map varying bank headers to Kuber's internal standard
        column_aliases = {
            'Description': 'Narration',
            'Particulars': 'Narration',
            'Remarks': 'Narration',
            'Transaction remarks': 'Narration',
            'Withdrawals': 'Debit',
            'Withdrawal': 'Debit',
            'Deposits': 'Credit',
            'Deposit': 'Credit'
        }
        df.rename(columns=column_aliases, inplace=True)
        
        # 🚨 THE CRITICAL FIX: Instantly convert any empty cells to 0 so Pandas math doesn't break
        df = df.fillna(0)
        
        # Model 1: Predict transaction categories
        df['Predicted_Category'] = classifier.predict(df['Narration'])
        
        def keyword_override(row):
            # 🌟 FIX 1: If it's an incoming credit (like Salary), instantly categorize it as Income!
            if float(row.get('Credit', 0)) > 0:
                return 'Income'
                
            narration = str(row['Narration']).upper()
            
            if any(k in narration for k in ['ZOMATO', 'SWIGGY', 'RESTAURANT', 'DINNER', 'FOOD']):
                return 'Food'
            if any(k in narration for k in ['AMAZON', 'MYNTRA', 'FLIPKART', 'ZUDIO', 'SHOPPING', 'APPARELS']):
                return 'Shopping'
            # 🌟 FIX 2: Added DIAGNOSTICS, BLOOD_TEST, and MEDPLUS to capture medical rows
            if any(k in narration for k in ['APOLLO', 'PHARMACY', 'PHARMEASY', 'MEDICINES', 'HOSPITAL', 'CLINIC', '1MG', 'PRACTO', 'DIAGNOSTICS', 'BLOOD_TEST', 'MEDPLUS']):
                return 'Healthcare'
            if any(k in narration for k in ['NETFLIX', 'SPOTIFY', 'BOOKMYSHOW', 'CONCERT', 'MOVIES', 'CINEMAS', 'MAKEMYTRIP', 'FLIGHT']):
                return 'Entertainment'
            if any(k in narration for k in ['RENT', 'MAINTENANCE', 'HOUSING', 'SOCIETY']):
                return 'Housing'
            if any(k in narration for k in ['BESCOM', 'ELECTRICITY', 'FIBER', 'JIO', 'AIRTEL', 'GAS', 'INDANE', 'WATER']):
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