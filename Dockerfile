FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY simulator/ ./simulator/

EXPOSE 5020
EXPOSE 8080

CMD ["python", "simulator/bhkw_simulator.py"]