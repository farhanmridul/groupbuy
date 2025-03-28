# Generated by Django 5.1.7 on 2025-03-28 11:04

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('orders', '0001_initial'),
        ('products', '0001_initial'),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name='cartitem',
            unique_together=set(),
        ),
        migrations.AddField(
            model_name='cartitem',
            name='is_market_price',
            field=models.BooleanField(default=False),
        ),
        migrations.AlterField(
            model_name='cartitem',
            name='product',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='products.product'),
        ),
        migrations.RemoveField(
            model_name='cartitem',
            name='created_at',
        ),
        migrations.RemoveField(
            model_name='cartitem',
            name='updated_at',
        ),
    ]
