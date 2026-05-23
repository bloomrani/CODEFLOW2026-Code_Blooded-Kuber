import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import make_pipeline
import joblib

print("1. Loading your Kaggle dataset...")
df = pd.read_csv('upi_transactions_2024.csv')

print("2. Engineering the missing 'Narration' column...")
narration_keywords = {
    'Grocery': ['BLINKIT', 'ZEPTO', 'BIGBASKET', 'DMART', 'RELIANCE_FRESH', 'INSTAMART'],
    'Food': ['ZOMATO', 'SWIGGY', 'MCDONALDS', 'STARBUCKS', 'DOMINOS_PIZZA', 'DINNER'],
    'Shopping': ['AMAZON', 'FLIPKART', 'MYNTRA', 'NYKAA', 'ZUDIO_APPARELS', 'DECATHLON_SPORTS', 'LIFESTYLE_STORES', 'AMAZON_INDIA'],
    'Fuel': ['INDIANOIL', 'HPCL', 'BPCL', 'SHELL'],
    'Entertainment': ['NETFLIX', 'SPOTIFY', 'BOOKMYSHOW', 'PVR', 'NETFLIX_SUBSCRIBE', 'SPOTIFY_PREMIUM', 'AMAZON_PRIME_SUBSCRIBE'],
    'Utilities': ['ELECTRICITY_BOARD', 'AIRTEL_FIBER', 'JIO_RECHARGE', 'BESCOM_ELECTRICITY_BILL', 'JIO_FIBER_BROADBAND', 'INDANE_GAS_AGENCY', 'WATER_BOARD_TAX', 'AIRTEL_POSTPAID_BILL'],
    'Transport': ['UBER', 'OLA', 'RAPIDO', 'IRCTC'],
    'Healthcare': ['APOLLO_PHARMACY', 'PHARMEASY', 'MEDPLUS', 'HOSPITAL', 'MAX_HOSPITAL_OPD', '1MG_MEDICINES', 'PRACTO_CONSULT'],
    'Education': ['COURSERA', 'UDEMY', 'COLLEGE_FEE', 'SCHOOL', 'COURSERA_LEARNING'],
    'Other': ['TRANSFER', 'NEFT', 'IMPS', 'ATM_WITHDRAWAL', 'FRIEND_REFUND', 'SALARY_MAY'],
    'Investment': ['HDFC_HOME_LOAN_EMI'] # Map this to teach the model about loans/investments
}


def generate_narration(row):
    category = row['merchant_category']
    
    keyword = np.random.choice(narration_keywords.get(category, ['MISC']))
    
    ref_num = np.random.randint(100000000, 999999999)
    return f"UPI/P2M/{keyword}/{ref_num}/MERCHANT"


df['Narration'] = df.apply(generate_narration, axis=1)

print("3. Training the Custom AI Model on 250,000 rows...")

ai_pipeline = make_pipeline(
    TfidfVectorizer(lowercase=True),
    MultinomialNB()
)


ai_pipeline.fit(df['Narration'], df['merchant_category'])

print("4. Saving the AI Brain...")
joblib.dump(ai_pipeline, 'bank_transaction_classifier.pkl')
print("✅ SUCCESS: Model saved as 'bank_transaction_classifier.pkl'")