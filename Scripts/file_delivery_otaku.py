import json
import os
import base64
import asyncio
import time
import requests
from telethon import TelegramClient, events, errors, Button
from telethon.tl.functions.channels import GetParticipantRequest
from telethon.errors import UserNotParticipantError

# ================= 1. CONFIGURATION =================
API_ID = 26533694
API_HASH = "36cbb9b7134615f4dd121aac7ba98ae0"
BOT_TOKEN = "8482679681:AAG98ABhFJlCHfyax1gft4ribuCU7nJOn84" 
ADMIN_ID = 8466952185 

# --- FORCE SUB SETTINGS ---
FORCE_SUB_CHANNEL = -1003277173361  
FORCE_SUB_LINK = "https://t.me/+G3e4doiQXFExMzU1" 

# Source Channels (Fallback)
SOURCE_CHANNELS = [
    -1003175788400, 
    -1003498912074   
]

# GitHub URLs
INDEX_URLS = [
    "https://raw.githubusercontent.com/OtaKuNexa/anime-index/main/anime_index.json",
    "https://raw.githubusercontent.com/CyberDrift00/anime-index/main/anime_index.json"
]

# Settings
CACHE_DURATION = 3600 # 1 Hour
last_fetch_time = 0   
ANIME_DATA = {}       

# 🔥 SAFETY SETTINGS
AUTO_DELETE_SECONDS = 900  # 15 Minutes
TRAFFIC_DELAY = 1.05       # Delay between batches

# ================= 2. INITIALIZATION =================
print("⚙️ Initializing Telegram Client...")
client = TelegramClient("secure_delivery_session", API_ID, API_HASH, connection_retries=None).start(bot_token=BOT_TOKEN)
BOT_USERNAME = ""

# ================= 3. MEMORY OPTIMIZED QUEUES =================

request_queue = asyncio.Queue()
pending_deletions = []

# --- WORKER 1: The Sender (Traffic Manager) ---
async def worker_distributor():
    print("👷 Sender Worker Started...")
    while True:
        batch = []
        while len(batch) < 30 and not request_queue.empty():
            item = await request_queue.get()
            batch.append(item)

        if not batch:
            await asyncio.sleep(0.1)
            continue

        for req in batch:
            await process_single_request(req)
            await asyncio.sleep(0.05) 
        
        await asyncio.sleep(TRAFFIC_DELAY) 

# --- WORKER 2: The Janitor (RAM Saver) ---
async def worker_janitor():
    print("🧹 Janitor Worker Started (RAM Optimized)...")
    global pending_deletions 
    
    while True:
        try:
            now = time.time()
            expired = [x for x in pending_deletions if x['delete_at'] <= now]
            pending_deletions = [x for x in pending_deletions if x['delete_at'] > now]
            
            for item in expired:
                try:
                    await client.delete_messages(item['chat_id'], item['msg_ids'])
                except Exception:
                    pass
            
            await asyncio.sleep(10)
        except Exception as e:
            print(f"🧹 Janitor Error: {e}")
            await asyncio.sleep(5)

async def process_single_request(req):
    target_chat_id, msg_id, channel_list = req
    sent_msg = None
    
    for channel_id in channel_list:
        try:
            sent_msg = await client.forward_messages(
                target_chat_id, 
                messages=msg_id, 
                from_peer=channel_id, 
                drop_author=True
            )
            if sent_msg: break 
        except errors.FloodWaitError as e:
            await asyncio.sleep(e.seconds)
        except Exception: continue
            
    if sent_msg:
        delete_time = time.time() + AUTO_DELETE_SECONDS
        pending_deletions.append({
            'delete_at': delete_time,
            'chat_id': target_chat_id,
            'msg_ids': [sent_msg.id]
        })
    else:
        print(f"❌ Failed to forward MsgID {msg_id}")

async def startup_checks():
    global BOT_USERNAME
    me = await client.get_me()
    BOT_USERNAME = me.username
    print(f"🤖 Bot Username: @{BOT_USERNAME}")
    asyncio.create_task(worker_distributor())
    asyncio.create_task(worker_janitor())

# ================= 4. DATA & UTILS (UPDATED) =================

def fetch_index_from_cloud():
    global last_fetch_time
    for url in INDEX_URLS:
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                last_fetch_time = time.time()
                return response.json()
        except Exception: pass
    return None

def get_data_with_cache():
    global ANIME_DATA
    if not ANIME_DATA or (time.time() - last_fetch_time) > CACHE_DURATION:
        new = fetch_index_from_cloud()
        if new: ANIME_DATA = new
    return ANIME_DATA

async def check_force_sub(user_id):
    try:
        entity = await client.get_entity(FORCE_SUB_CHANNEL)
        await client(GetParticipantRequest(channel=entity, participant=user_id))
        return True
    except: return False

# ✅ NEW: Helper to inflate the optimized JSON back to standard dicts
def normalize_files(raw_list, default_channel_id):
    normalized = []
    if not isinstance(raw_list, list): return []
    
    for item in raw_list:
        # Case 1: Optimized Integer (Use Parent Channel ID)
        if isinstance(item, int):
            if default_channel_id:
                normalized.append({"file": item, "channel_id": default_channel_id})
        
        # Case 2: Dictionary Exception (Use its own Channel ID)
        elif isinstance(item, dict):
            # Fallback to default if dictionary doesn't have an ID (unlikely but safe)
            cid = item.get("channel_id", default_channel_id)
            if cid and "file" in item:
                normalized.append({"file": item["file"], "channel_id": cid})
                
    return normalized

# ✅ UPDATED: Search logic to handle "languages" and Hoisted Channel IDs
def find_batch_in_season(season_data, batch_key):
    target_key = batch_key.lower().strip()
    
    # 1. NEW STRUCTURE CHECK: Look inside "languages"
    if "languages" in season_data:
        for lang_data in season_data["languages"].values():
            # Capture the hoisted ID
            default_cid = lang_data.get("channel_id")
            
            # Check Batches
            if "batches" in lang_data:
                for b_key, b_val in lang_data["batches"].items():
                    if b_key.lower().strip() == target_key:
                        return normalize_files(b_val, default_cid)
            
            # Check Specials
            if "specials" in lang_data:
                # If target is specific special key
                for s_key, s_val in lang_data["specials"].items():
                    if s_key.lower().strip() == target_key:
                        return normalize_files(s_val, default_cid)

    # 2. FALLBACK: Old Recursive Search (for backward compatibility)
    def search_recursive(data):
        if isinstance(data, dict):
            for k, v in data.items():
                if k.lower().strip() == target_key: return v
            for v in data.values():
                if isinstance(v, dict):
                    res = search_recursive(v)
                    if res: return res
        return None
    
    res = search_recursive(season_data)
    # If found via recursive search, assume it's the old list-of-dicts format
    if res and isinstance(res, list):
        return res
        
    return None

# ================= 5. BOT HANDLERS =================

@client.on(events.NewMessage(pattern='/refresh'))
async def refresh_data(event):
    if event.sender_id != ADMIN_ID: return
    fetch_index_from_cloud()
    await event.reply("✅ **Data Refreshed!**")

@client.on(events.NewMessage(pattern=r"/start (.+)"))
async def batch_handler(event):
    payload = event.pattern_match.group(1).strip()
    user_id = event.sender_id
    
    if not await check_force_sub(user_id):
        return await event.reply(
            "⚠️ **Access Denied**\nPlease join our channel first.",
            buttons=[[Button.url("📢 Join Channel", FORCE_SUB_LINK)], 
                     [Button.url("🔄 Try Again", f"https://t.me/{BOT_USERNAME}?start={payload}")]]
        )

    try:
        decoded = base64.urlsafe_b64decode(payload + '===').decode('utf-8')
        parts = decoded.split('|')
        
        if len(parts) == 3:
            anime, season, batch = parts
        else:
            await event.reply("⚠️ **Invalid Link Format.**")
            return
        
        data = get_data_with_cache()
        if anime not in data: return await event.reply("⚠️ **Anime Not Found.**")

        # Find Season (Case Insensitive)
        season_node = next((v for k, v in data[anime].get("seasons", {}).items() if k.lower() == season.lower()), None)
        if not season_node: return await event.reply("⚠️ **Season Not Found.**")

        # Find Files (Optimized Search)
        files = find_batch_in_season(season_node, batch)
        if not files: return await event.reply("⚠️ **Batch Not Found.**")

        q_size = request_queue.qsize()
        traffic_msg = ""
        if q_size > 100: traffic_msg = f"\n🚦 **High Load:** {q_size} requests pending."
        elif q_size > 30: traffic_msg = f"\n🚦 **Queue:** {q_size} requests ahead."

        status_msg = await event.reply(f"📂 **{anime}**\n💿 {season} - {batch}\n🚀 **Queued.**{traffic_msg}\n\n_Auto-deletes in 15 mins._")

        pending_deletions.append({
            'delete_at': time.time() + AUTO_DELETE_SECONDS,
            'chat_id': event.chat_id,
            'msg_ids': [status_msg.id]
        })

        for item in files:
            # Files are now normalized to dicts: {"file": 123, "channel_id": -100...}
            if not isinstance(item, dict): continue
            
            msg_id = item.get('file')
            if not msg_id: continue

            # Construct Channel List based on JSON ID
            ch_list = []
            json_ch_id = item.get('channel_id')

            if json_ch_id:
                ch_list.append(int(str(json_ch_id).strip()))
            else:
                # Fallback only if JSON is broken/missing ID
                ch_list.extend(SOURCE_CHANNELS)
            
            await request_queue.put((event.chat_id, msg_id, ch_list))

    except Exception as e:
        # await event.reply(f"❌ Error: {e}")
        pass

@client.on(events.NewMessage(pattern=r"^/start$"))
async def block_direct(event):
    await event.reply("⛔ **Access Denied.**")

# ================= 6. RUN =================
print("🔒 Secure Delivery Bot is Running...")
client.loop.run_until_complete(startup_checks())
client.run_until_disconnected()