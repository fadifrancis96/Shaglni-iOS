package com.shaglni.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shaglni.app.ui.localization.LocalizationManager
import java.util.Locale

@Composable
fun LanguageSwitcher(
    modifier: Modifier = Modifier,
    onLanguageChanged: (Locale) -> Unit = {}
) {
    var selectedLanguage by remember { mutableStateOf(LocalizationManager.getLocale().language) }

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // English Option
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(
                    selected = selectedLanguage == "en",
                    onClick = {
                        selectedLanguage = "en"
                        LocalizationManager.setLocale(Locale.ENGLISH)
                        onLanguageChanged(Locale.ENGLISH)
                    },
                    colors = RadioButtonDefaults.colors(selectedColor = MaterialTheme.colorScheme.primary)
                )
                Text(
                    text = "English",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = if (selectedLanguage == "en") FontWeight.Bold else FontWeight.Normal
                )
            }

            // Arabic Option
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(
                    selected = selectedLanguage == "ar",
                    onClick = {
                        selectedLanguage = "ar"
                        LocalizationManager.setLocale(Locale("ar"))
                        onLanguageChanged(Locale("ar"))
                    },
                    colors = RadioButtonDefaults.colors(selectedColor = MaterialTheme.colorScheme.primary)
                )
                Text(
                    text = "العربية",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = if (selectedLanguage == "ar") FontWeight.Bold else FontWeight.Normal
                )
            }
        }
    }
}
