# Generated by Django 5.0.dev20230213052949 on 2023-07-04 14:00

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("chat", "0006_alter_chat_avatar_alter_userprofile_avatar"),
    ]

    operations = [
        migrations.AlterField(
            model_name="chat",
            name="avatar",
            field=models.ImageField(
                blank=True, default="img_212915.jpg", upload_to="chat_photos/"
            ),
        ),
        migrations.AlterField(
            model_name="userprofile",
            name="avatar",
            field=models.ImageField(
                blank=True, default="img_212915.jpg", upload_to="user_photos/"
            ),
        ),
    ]
