# Generated by Django 5.0.dev20230213052949 on 2023-10-01 18:12

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("chat", "0009_alter_chat_avatar_alter_userprofile_avatar"),
    ]

    operations = [
        migrations.AddField(
            model_name="chatmembers",
            name="left_att",
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
