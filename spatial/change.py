import pandas as pd

# read csv, change 'US_Accidents_March23.csv' to your real file path
df = pd.read_csv('US_Accidents_March23.csv', skiprows=1)

# keep 10 columns
df = df.iloc[:, :10]

# save to a new file, change the real saved path
df.to_csv('US_Accidents_March_10.csv', index=False)
