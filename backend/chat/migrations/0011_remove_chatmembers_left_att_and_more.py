# Generated by Django 5.0.dev20230213052949 on 2023-10-01 18:15

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("chat", "0010_chatmembers_left_att"),
    ]

    operations = [
        migrations.RemoveField(
            model_name="chatmembers",
            name="left_att",
        ),
        migrations.AlterField(
            model_name="chatmembers",
            name="left_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
