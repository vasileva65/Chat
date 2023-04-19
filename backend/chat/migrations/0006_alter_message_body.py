# Generated by Django 5.0.dev20230213052949 on 2023-04-05 06:58

from django.db import migrations, models
import profanity.validators


class Migration(migrations.Migration):
    dependencies = [
        ("chat", "0005_rename_profile_userprofile_user"),
    ]

    operations = [
        migrations.AlterField(
            model_name="message",
            name="body",
            field=models.TextField(
                validators=[profanity.validators.validate_is_profane]
            ),
        ),
    ]