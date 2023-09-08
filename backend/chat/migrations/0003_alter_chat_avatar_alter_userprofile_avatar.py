# Generated by Django 5.0.dev20230213052949 on 2023-07-04 12:09

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("chat", "0002_alter_chat_avatar_alter_userprofile_avatar"),
    ]

    operations = [
        migrations.AlterField(
            model_name="chat",
            name="avatar",
            field=models.ImageField(
                blank=True,
                default="/media/chat_photos/img_212915.png",
                null=True,
                upload_to="chat_photos/",
            ),
        ),
        migrations.AlterField(
            model_name="userprofile",
            name="avatar",
            field=models.ImageField(
                blank=True,
                default="/media/user_photos/img_212915.png",
                null=True,
                upload_to="user_photos/",
            ),
        ),
    ]