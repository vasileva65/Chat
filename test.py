from locust import HttpUser, TaskSet, task, between

class UserBehavior(TaskSet):

    def on_start(self):
        # Регистрация нового пользователя
        self.register()
        # if self.username and self.user_id:
        #     self.login()
        # else:
        #     print("Failed to get username or user_id")

    def register(self):
        response = self.client.post(
            "/register/", 
            json={
                "first_name": "Джон",
                "last_name": "Дор",
                "middle_name": "Смит",
                "password": "testpassword-0",
                "password2": "testpassword-0"
            }
        )
        if response.status_code == 201:
            print("User registered successfully")
            # Логин после успешной регистрации
            
            user_data = response.json()
            user_info = user_data.get('user', {})
            user_id = user_info.get('id')
            username = user_info.get('username')
            print("SELF USERNAME BEFORE")
            self.username = user_info.get('username')
            self.user_id = user_info.get('id')
            print(self.username)
            print(self.user_id)

            # print(user_data)
            # print(user_id)
            # print(username)
            print("LOGIN BEFORE")
            self.login()
            # Возвращаем id и username
            # return username, user_id
        else:
            print("Failed to register user")
            return None, None

    def login(self):
        response = self.client.post(
            "/token/", 
            json={
                "username": self.username,  # используем имя пользователя, которое вы указали при регистрации
                "password": "testpassword-0"
            }
        )
        if response.status_code == 200:
            print("User logged in successfully")
            # сохраняем токен для дальнейшего использования
            self.user_access_token = response.json()['access']
            self.client.headers["Authorization"] = f"Bearer {self.user_access_token}"
            # автоматическое добавление пользователя в чат
            self.add_user_to_chat()
            # открытие чата и отправка сообщения
            self.open_chat_and_send_message()
        else:
            print("Failed to log in user")

    def add_user_to_chat(self):
        # Добавляем пользователя в чат (замените chat_id на реальный идентификатор чата)
        chat_id = 1
        print(self.user_id)
        response = self.client.patch(f"/chats/partial_update/1/", json={"user_ids": [self.user_id], "admin_id": 1})
        print("RESPONSE")
        print(response)
        if response.status_code == 200:
            print("User added to chat successfully")
        else:
            print("Failed to add user to chat")

    @task(2)
    def open_chat_and_send_message(self):
        # Открываем чат (замените chat_id на реальный идентификатор чата)
        chat_id = 1
        response = self.client.get(f"/chats/{chat_id}/")
        if response.status_code == 200:
            print("Chat opened successfully")
            # Отправляем сообщение в чат
            response = self.client.post(f"/messages/", json={"chat_id": chat_id, "body": "тест", "sender_id": self.user_id})
            if response.status_code == 201:
                print("Message sent successfully")
            else:
                print("Failed to send message")
        else:
            print("Failed to open chat")

class WebsiteUser(HttpUser):
    tasks = {UserBehavior: 1}
    wait_time = between(5, 9)
