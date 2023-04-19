import aiohttp
import asyncio
from aiohttp import ClientSession


async def loop():
    session = ClientSession()
    async with session.ws_connect('ws://localhost:8080/ws') as ws:
        async for msg in ws:
            if msg.type == aiohttp.WSMsgType.TEXT:
                if msg.data == 'close cmd':
                    await ws.close()
                    break
                else:
                    print(msg.data)
            elif msg.type == aiohttp.WSMsgType.ERROR:
                break

l = asyncio.new_event_loop()
l.run_until_complete(loop())
