# Generated by Django 5.0.dev20230213052949 on 2023-04-15 12:32

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("chat", "0009_alter_userprofile_avatar"),
    ]

    operations = [
        migrations.AlterField(
            model_name="userprofile",
            name="avatar",
            field=models.ImageField(blank=True, null=True, upload_to="user_photos/"),
        ),
    ]
