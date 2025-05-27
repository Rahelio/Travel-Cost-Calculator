from flask import Flask, render_template, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os
import requests
import re
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__, static_url_path='/travel-calculator/static')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///travel_costs.db'
app.config['APPLICATION_ROOT'] = '/travel-calculator'
db = SQLAlchemy(app)

def format_postcode(postcode):
    """Format UK postcode to standard format."""
    # Remove all spaces and convert to uppercase
    postcode = postcode.replace(" ", "").upper()
    
    # Insert space before the last 3 characters
    if len(postcode) > 3:
        postcode = postcode[:-3] + " " + postcode[-3:]
    
    return postcode

def validate_postcode(postcode):
    """Validate UK postcode format."""
    # UK postcode regex pattern
    pattern = r'^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$'
    return bool(re.match(pattern, postcode))

# Database Model
class TravelRecord(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    start_postcode = db.Column(db.String(10), nullable=False)
    end_postcode = db.Column(db.String(10), nullable=False)
    base_rate = db.Column(db.Float, nullable=False)
    travel_time = db.Column(db.Integer, nullable=False)
    total_cost = db.Column(db.Float, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

class TravelCostService:
    def __init__(self, api_key):
        self.api_key = api_key
        self.base_url = "https://maps.googleapis.com/maps/api/distancematrix/json"

    def calculate_travel_time(self, start_postcode, end_postcode):
        # Format postcodes
        start_postcode = format_postcode(start_postcode)
        end_postcode = format_postcode(end_postcode)
        
        # Validate postcodes
        if not validate_postcode(start_postcode):
            raise Exception("Invalid start postcode format")
        if not validate_postcode(end_postcode):
            raise Exception("Invalid end postcode format")
            
        url = f"{self.base_url}?origins={start_postcode}&destinations={end_postcode}&mode=driving&key={self.api_key}"
        
        try:
            response = requests.get(url)
            response.raise_for_status()
            data = response.json()
            
            if data['status'] != 'OK':
                raise Exception(f"Google Maps API error: {data['status']}")
            
            duration = data['rows'][0]['elements'][0]['duration']['value']
            return duration
        except Exception as e:
            raise Exception(f"Error calculating travel time: {str(e)}")

# Initialize the travel cost service
travel_service = TravelCostService(api_key=os.getenv('GOOGLE_MAPS_API_KEY'))

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/calculate', methods=['POST'])
def calculate():
    try:
        data = request.get_json()
        start_postcode = data.get('startPostcode')
        end_postcode = data.get('endPostcode')
        base_rate = float(data.get('baseRate', 0))

        if not all([start_postcode, end_postcode, base_rate]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Calculate travel time
        travel_time = travel_service.calculate_travel_time(start_postcode, end_postcode)
        
        # Calculate costs
        minutes = travel_time / 60.0
        cost_per_minute = base_rate / 60.0
        time_based_cost = minutes * cost_per_minute
        total_cost = time_based_cost + base_rate

        # Save to database
        record = TravelRecord(
            start_postcode=start_postcode,
            end_postcode=end_postcode,
            base_rate=base_rate,
            travel_time=travel_time,
            total_cost=total_cost
        )
        db.session.add(record)
        db.session.commit()

        return jsonify({
            'travelTime': travel_time,
            'totalCost': total_cost,
            'timeBasedCost': time_based_cost,
            'costPerMinute': cost_per_minute
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='127.0.0.1', port=8003, debug=True) 