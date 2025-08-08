import streamlit as st
import pandas as pd
import json
from datetime import datetime
import time

# Path ke file log Suricata
EVE_JSON_PATH = "/var/log/suricata/eve.json"

# Konfigurasi halaman Streamlit
st.set_page_config(
    page_title="Real-Time Network Monitoring",
    page_icon="🛡️",
    layout="wide",
)

# Fungsi untuk membaca dan mem-parsing log eve.json
def load_data(log_file):
    data = []
    try:
        with open(log_file, 'r') as f:
            for line in f:
                data.append(json.loads(line))
    except FileNotFoundError:
        st.warning(f"Log file not found at: {log_file}. Is Suricata running?")
    except json.JSONDecodeError as e:
        st.warning(f"Error decoding JSON: {e}. The log file might be corrupted or empty.")
    except Exception as e:
        st.error(f"An unexpected error occurred while loading data: {e}")
    return pd.DataFrame(data)

# Judul utama dashboard
st.title("🛡️ Real-Time Network Monitoring Dashboard")
st.markdown("Powered by Suricata & Streamlit")

# Placeholder untuk auto-refresh dan data
placeholder = st.empty()

# Loop untuk refresh data secara real-time
while True:
    df = load_data(EVE_JSON_PATH)

    with placeholder.container():
        try:
            if not df.empty:
                st.success(f"Successfully loaded {len(df)} events from Suricata.")
                st.markdown(f"*Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}* | Refreshing every 10 seconds...")

                # --- Ringkasan Umum ---
                st.header("📊 General Overview")
                total_events = len(df)
                # Safely get 'event_type' column, handle if it doesn't exist
                event_types = df['event_type'].nunique() if 'event_type' in df.columns else 0
                alerts = df[df['event_type'] == 'alert'].shape[0] if 'event_type' in df.columns and 'alert' in df['event_type'].unique() else 0

                col1, col2, col3 = st.columns(3)
                col1.metric("Total Events", total_events)
                col2.metric("Unique Event Types", event_types)
                col3.metric("Total Alerts", alerts)

                # --- Analisis Peringatan (Alerts) ---
                st.header("🚨 Alert Analysis")
                alerts_df = pd.DataFrame() # Initialize empty DataFrame
                if 'event_type' in df.columns:
                    alerts_df = df[df['event_type'] == 'alert'].copy()

                if not alerts_df.empty:
                    # Ekstrak informasi dari kolom 'alert'
                    # Ensure 'alert' column exists before applying lambda
                    if 'alert' in alerts_df.columns:
                        alerts_df['signature'] = alerts_df['alert'].apply(lambda x: x.get('signature', 'N/A') if isinstance(x, dict) else 'N/A')
                        alerts_df['category'] = alerts_df['alert'].apply(lambda x: x.get('category', 'N/A') if isinstance(x, dict) else 'N/A')
                        alerts_df['severity'] = alerts_df['alert'].apply(lambda x: x.get('severity', 'N/A') if isinstance(x, dict) else 'N/A')
                    else:
                        st.warning("Alerts found, but 'alert' column is missing or malformed.")
                        alerts_df['signature'] = 'N/A'
                        alerts_df['category'] = 'N/A'
                        alerts_df['severity'] = 'N/A'


                    # Tampilkan 10 peringatan teratas
                    st.subheader("Top 10 Alert Signatures")
                    if 'signature' in alerts_df.columns:
                        st.bar_chart(alerts_df['signature'].value_counts().head(10))
                    else:
                        st.info("No signatures to display.")

                    # Tampilkan tabel detail peringatan
                    st.subheader("Alert Details")
                    display_cols = ['timestamp', 'src_ip', 'dest_ip', 'dest_port', 'signature', 'category', 'severity']
                    # Filter for columns that actually exist in alerts_df
                    existing_display_cols = [col for col in display_cols if col in alerts_df.columns]
                    st.dataframe(alerts_df[existing_display_cols])
                else:
                    st.info("No alerts recorded yet.")

                # --- Analisis Lalu Lintas Jaringan ---
                st.header("🌐 Network Traffic Analysis")
                traffic_df = pd.DataFrame() # Initialize empty DataFrame
                if 'event_type' in df.columns:
                    traffic_df = df[df['event_type'].isin(['flow', 'netflow'])].copy()

                if not traffic_df.empty:
                    st.subheader("Top 10 Source IPs")
                    if 'src_ip' in traffic_df.columns:
                        st.bar_chart(traffic_df['src_ip'].value_counts().head(10))
                    else:
                        st.info("No source IPs to display.")

                    st.subheader("Top 10 Destination IPs")
                    if 'dest_ip' in traffic_df.columns:
                        st.bar_chart(traffic_df['dest_ip'].value_counts().head(10))
                    else:
                        st.info("No destination IPs to display.")
                else:
                    st.info("No flow/netflow events recorded yet.")

                # --- Tampilkan Raw Data (opsional) ---
                with st.expander("Raw Event Log (Last 100 entries)"):
                    st.dataframe(df.tail(100))
            else:
                st.info("Waiting for Suricata to generate events...")
                st.markdown(f"*Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}* | Refreshing every 10 seconds...")
        except Exception as e:
            st.error(f"An error occurred during dashboard rendering: {e}")
            st.info("Attempting to refresh in 10 seconds...")

    time.sleep(10) # Refresh setiap 10 detik