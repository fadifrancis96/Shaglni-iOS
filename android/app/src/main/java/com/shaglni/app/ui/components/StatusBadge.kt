package com.shaglni.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun StatusBadge(
    status: String,
    modifier: Modifier = Modifier
) {
    val (backgroundColor, textColor) = when (status.lowercase()) {
        "open" -> Color(0xFF4CAF50) to Color.White
        "in_progress" -> Color(0xFF2196F3) to Color.White
        "completed" -> Color(0xFF9E9E9E) to Color.White
        "cancelled" -> Color(0xFFF44336) to Color.White
        "pending" -> Color(0xFFFF9800) to Color.White
        "accepted" -> Color(0xFF4CAF50) to Color.White
        "rejected" -> Color(0xFFF44336) to Color.White
        "counter_offer" -> Color(0xFF2196F3) to Color.White
        else -> MaterialTheme.colorScheme.surfaceVariant to MaterialTheme.colorScheme.onSurfaceVariant
    }

    Text(
        text = status.replace("_", " ").uppercase(),
        modifier = modifier
            .background(
                color = backgroundColor,
                shape = RoundedCornerShape(12.dp)
            )
            .padding(horizontal = 8.dp, vertical = 4.dp),
        color = textColor,
        style = MaterialTheme.typography.labelSmall,
        fontWeight = FontWeight.Medium
    )
}
