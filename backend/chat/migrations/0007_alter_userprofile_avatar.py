# Generated by Django 5.0.dev20230213052949 on 2023-04-11 15:27

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("chat", "0006_alter_message_body"),
    ]

    operations = [
        migrations.AlterField(
            model_name="userprofile",
            name="avatar",
            field=models.ImageField(upload_to="user/profile/"),
        ),
    ]
