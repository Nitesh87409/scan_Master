package com.scanner.poc.model

/**
 * ScanMode: The two scanning modes.
 */
enum class ScanMode {
    DOCUMENT,
    ID_CARD
}

/**
 * IdCardStep: Which side of the ID Card are we currently scanning?
 */
enum class IdCardStep {
    FRONT,   // Waiting for front side scan
    BACK,    // Front done, waiting for back side
    DONE     // Both sides done, ready to merge & save
}
