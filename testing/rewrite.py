
import csv
from pathlib import Path

input_path = Path("requests.csv")
output_path = Path("urls.txt")

server="http://v4a.mwt2.org:6082"

# Open the CSV with proper newline/encoding handling
with input_path.open(mode="r", encoding="utf-8", newline="") as infile, \
     output_path.open(mode="w", encoding="utf-8", newline="") as outfile:
    
    # The default csv reader handles quoted fields correctly
    reader = csv.reader(infile)
    
    for row in reader:
        # Skip empty rows
        if not row:
            continue
        
        # Expecting at least two columns; take the second (index 1)
        if len(row) >= 2:
            url = row[1].strip()
            outfile.write(server + url + "\n")
        else:
            # If a row is malformed (only one column), you can choose to skip or log
            # Here we skip silently; uncomment the next line to log:
            # print(f"Skipping malformed row: {row}")
            continue

print("Done. Extracted second column to urls.txt")
