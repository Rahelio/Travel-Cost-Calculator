# Travel Cost Calculator (Python Web Version)

This is a Python web application version of the Travel Cost Calculator, built with Flask and using the Google Maps API for travel time calculations.

## Features

- Calculate travel costs between two postcodes
- Real-time travel time calculation using Google Maps API
- Modern, responsive web interface
- Cost breakdown with detailed calculations
- Persistent storage of calculation history

## Prerequisites

- Python 3.8 or higher
- Google Maps API key

## Setup

1. Create a virtual environment and activate it:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Create a `.env` file in the project root and add your Google Maps API key:
```
GOOGLE_MAPS_API_KEY=your_api_key_here
```

4. Initialize the database:
```bash
python app.py
```

## Running the Application

1. Start the Flask development server:
```bash
python app.py
```

2. Open your web browser and navigate to:
```
http://localhost:5000
```

## Usage

1. Enter the start postcode
2. Enter the end postcode
3. Enter your hourly base rate
4. Click "Calculate Cost" to see the detailed breakdown

## Technical Details

- Built with Flask web framework
- Uses SQLAlchemy for database management
- Implements Google Maps Distance Matrix API
- Modern UI with responsive design
- Real-time calculations with loading states
- Error handling and user feedback 