# Generated by Django 5.0.dev20230213052949 on 2023-03-28 07:17

from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ("chat", "0004_rename_user_userprofile_profile"),
    ]

    operations = [
        migrations.RenameField(
            model_name="userprofile",
            old_name="profile",
            new_name="user",
        ),
    ]
