import streamlit as st
import random

st.set_page_config(page_title="Monitoring", layout="wide")
st.title("📊 Network Monitoring Dashboard")
st.line_chart([random.randint(10, 100) for _ in range(20)])
