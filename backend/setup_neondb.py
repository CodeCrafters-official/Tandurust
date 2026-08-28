"""
NeonDB Setup Script for Tandurust
==================================
Run this after configuring your .env file with NeonDB credentials.

Steps:
1. Go to https://neon.tech and sign up (free tier available)
2. Create a new project named "tandurust"
3. Copy the connection string from the dashboard
4. Paste it in backend/.env as DATABASE_URL
5. Run: python setup_neondb.py
"""
import os
import sys
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL', '')

if 'sqlite' in DATABASE_URL:
    print("ERROR: .env still has SQLite URL.")
    print("Please update DATABASE_URL in .env with your NeonDB PostgreSQL connection string.")
    print("\nExample:")
    print("DATABASE_URL=postgresql://user:password@ep-xxxx.us-east-2.aws.neon.tech/tandurust?sslmode=require")
    sys.exit(1)

if 'neon' not in DATABASE_URL and 'postgresql' not in DATABASE_URL:
    print("ERROR: DATABASE_URL doesn't look like a PostgreSQL connection string.")
    sys.exit(1)

print(f"Connecting to: {DATABASE_URL.split('@')[1].split('/')[0] if '@' in DATABASE_URL else 'unknown'}...")

# Import app to create tables and seed data
from app import app, db, seed_facilities, seed_asha_workers, seed_patients, seed_doctors, seed_high_risk, seed_visits

with app.app_context():
    print("Creating all tables...")
    db.create_all()
    print("Tables created successfully!")

    print("\nSeeding data...")
    seed_facilities()
    seed_asha_workers()
    seed_patients()
    seed_doctors()
    seed_high_risk()
    seed_visits()

    print("\n=== NeonDB Setup Complete! ===")
    print("Your Tandurust database is ready on NeonDB.")
    print("Run 'python app.py' to start the server.")
