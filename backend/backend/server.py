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
                await ws.send_str(msg.data + '/answer')
        elif msg.type == aiohttp.WSMsgType.ERROR:
            print('ws connection closed with exception %s' %
                  ws.exception())

    print('websocket connection closed')
    
    return ws

app = web.Application()
app.add_routes([web.get('/', hello)])
#в этом канале chat_id  
app.add_routes([web.get('/ws', websocket_handler)])

web.run_app(app)