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
        print(f"Making request to Google Maps API with URL: {url}")  # Debug log
        
        try:
            response = requests.get(url)
            response.raise_for_status()
            data = response.json()
            print(f"Google Maps API response: {data}")  # Debug log
            
            if data['status'] != 'OK':
                error_message = f"Google Maps API error: {data['status']}"
                if 'error_message' in data:
                    error_message += f" - {data['error_message']}"
                raise Exception(error_message)
            
            if not data['rows'] or not data['rows'][0]['elements']:
                raise Exception("No route found between the provided postcodes")
            
            element = data['rows'][0]['elements'][0]
            if element['status'] != 'OK':
                raise Exception(f"Route calculation failed: {element['status']}")
            
            duration = element['duration']['value']
            return duration
        except requests.exceptions.RequestException as e:
            print(f"Network error: {str(e)}")  # Debug log
            raise Exception(f"Network error: {str(e)}")
        except Exception as e:
            print(f"Error calculating travel time: {str(e)}")  # Debug log
            raise Exception(f"Error calculating travel time: {str(e)}")

# Initialize the travel cost service
travel_service = TravelCostService(api_key=os.getenv('GOOGLE_MAPS_API_KEY'))

# Add CORS support
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
    response.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
    return response

@app.route('/')
def index():
    print("Serving index page")  # Debug log
    return render_template('index.html')

@app.route('/calculate', methods=['POST', 'OPTIONS'])
def calculate():
    if request.method == 'OPTIONS':
        return '', 200
        
    print(f"Received {request.method} request to /calculate")  # Debug log
    print(f"Request headers: {dict(request.headers)}")  # Debug log
    
    try:
        data = request.get_json()
        print("Received request data:", data)  # Debug log
        
        if not data:
            print("No JSON data received")  # Debug log
            return jsonify({'error': 'No data received'}), 400
        
        start_postcode = data.get('startPostcode')
        end_postcode = data.get('endPostcode')
        base_rate = float(data.get('baseRate', 0))

        print(f"Parsed data - Start: {start_postcode}, End: {end_postcode}, Rate: {base_rate}")  # Debug log

        if not all([start_postcode, end_postcode, base_rate]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Calculate travel time
        try:
            travel_time = travel_service.calculate_travel_time(start_postcode, end_postcode)
            print(f"Calculated travel time: {travel_time} seconds")  # Debug log
        except Exception as e:
            print(f"Error calculating travel time: {str(e)}")  # Debug log
            return jsonify({'error': str(e)}), 500
        
        # Calculate costs
        minutes = travel_time / 60.0
        cost_per_minute = base_rate / 60.0
        time_based_cost = minutes * cost_per_minute
        total_cost = time_based_cost + base_rate

        print(f"Calculated costs - Minutes: {minutes}, Cost per minute: {cost_per_minute}, Total: {total_cost}")  # Debug log

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

        response_data = {
            'travelTime': travel_time,
            'totalCost': total_cost,
            'timeBasedCost': time_based_cost,
            'costPerMinute': cost_per_minute
        }
        print("Sending response:", response_data)  # Debug log
        return jsonify(response_data)

    except Exception as e:
        print(f"Unexpected error: {str(e)}")  # Debug log
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='127.0.0.1', port=8003, debug=True) 