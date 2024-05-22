from aiohttp import web
import aiohttp

usersOnline = {
    #user_id 1: хранит объект connection of this user
}

usersInChat = {
    #chat_id хранит список users_id
    
}

connections = [

]

async def hello(request):
    print(request.query)
    chat_id = request.query['chat_id']
    for connection in connections:
        if not connection.closed:
            await connection.send_str(chat_id)
    return web.Response(text="Hello, world")

async def websocket_handler(request):

    ws = web.WebSocketResponse()
    await ws.prepare(request)
    connections.append(ws) 

    async for msg in ws:
        if msg.type == aiohttp.WSMsgType.TEXT:
            if msg.data == 'close':
                await ws.close()
            else:
                # handle incoming message, e.g., add user to chat
                data = msg.data.split(',')
                if data[0] == 'add_user_to_chat':
                    chat_id = int(data[1])
                    user_id = int(data[2])
                    await add_user_to_chat(chat_id, user_id)
                await ws.send_str(msg.data + '/answer')
        elif msg.type == aiohttp.WSMsgType.ERROR:
            print('ws connection closed with exception %s' % ws.exception())

    print('websocket connection closed')
    connections.remove(ws)  # Remove the connection when closed
    return ws

async def add_user_to_chat(chat_id, user_id):
    if chat_id in usersInChat:
        usersInChat[chat_id].append(user_id)
    else:
        usersInChat[chat_id] = [user_id]

    # Notify all users in this chat
    for user in usersInChat[chat_id]:
        if user in usersOnline:
            connection = usersOnline[user]
            if not connection.closed:
                await connection.send_str(f"User {user_id} added to chat {chat_id}")
                
app = web.Application()
app.add_routes([web.get('/', hello)])
#в этом канале chat_id  
app.add_routes([web.get('/ws', websocket_handler)])

web.run_app(app)