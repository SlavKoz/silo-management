# Color Coding Concept for Commodities, Grain Groups, and Variants

## Overview

This document defines the visual coding system for the three-level hierarchy:
**Commodity → Grain Group → Variant**

### Hierarchy Levels

1. **Commodities** (27 unique) - Assigned **distinct base colors** (different hues)
2. **Grain Groups** (100+ unique) - Assigned **shades** of their commodity's base color (same hue, different lightness)
3. **Variants** (473 items) - Assigned **patterns/textures** on top of their grain group's color

---

## Color Scheme Design

### Level 1: Commodities (Base Colors)

Each commodity family gets a distinct hue to make them immediately recognizable:

| Commodity Code | Name | Base Color | Hex Code | Color Family |
|---|---|---|---|---|
| **WHT** | Wheat | Goldenrod | `#DAA520` | Golden/Yellow |
| **OSR** | Oilseed Rape | Gold | `#FFD700` | Bright Yellow |
| **MBLY** | Malting Barley | Saddle Brown | `#8B4513` | Dark Brown |
| **FBLY** | Feed Barley | Peru | `#CD853F` | Light Brown |
| **PEAS** | Peas | Lime Green | `#32CD32` | Green |
| **BNS** | Beans | Forest Green | `#228B22` | Dark Green |
| **OATS** | Oats | Wheat | `#F5DEB3` | Cream/Beige |
| **LIN** | Linseed | Royal Blue | `#4169E1` | Blue |
| **RYE** | Rye | Slate Gray | `#708090` | Gray |
| **TRI** | Triticale | Medium Purple | `#9370DB` | Purple |
| **MILL** | Millet | Lemon Chiffon | `#FFFACD` | Pale Yellow |
| **WARB** | Warburtons | Crimson | `#DC143C` | Red |
| **IMP** | Import | Dark Gray | `#A9A9A9` | Gray |

### Derivative Commodities

#### In-Country (IC) Variants
Lighter/desaturated versions of base commodities:

| Commodity Code | Name | Base Color | Hex Code |
|---|---|---|---|
| **ICWHT** | IC Wheat | Khaki | `#F0E68C` |
| **ICMBLY** | IC Malting Barley | Sienna | `#A0522D` |
| **ICFBLY** | IC Feed Barley | Burlywood | `#DEB887` |
| **ICPEAS** | IC Peas | Light Green | `#90EE90` |
| **ICBNS** | IC Beans | Medium Sea Green | `#3CB371` |
| **ICOATS** | IC Oats | Antique White | `#FAEBD7` |

#### Organic (OG) Variants
Earthy/muted tones of base commodities:

| Commodity Code | Name | Base Color | Hex Code |
|---|---|---|---|
| **OGWHT** | Organic Wheat | Old Gold | `#D4AF37` |
| **OGMBLY** | Organic Malting Barley | Dark Brown | `#654321` |
| **OGFBLY** | Organic Feed Barley | Dark Goldenrod | `#B8860B` |
| **OGPEAS** | Organic Peas | Olive Drab | `#6B8E23` |
| **OGBNS** | Organic Beans | Dark Olive Green | `#556B2F` |
| **OGOATS** | Organic Oats | Pale Goldenrod | `#EEE8AA` |
| **OGRYE** | Organic Rye | Dim Gray | `#696969` |
| **OGTRI** | Organic Triticale | Medium Slate Blue | `#7B68EE` |

---

### Level 2: Grain Groups (Color Shades)

Each grain group within a commodity gets a shade (lighter or darker) of the commodity's base color.

**Example: Wheat (WHT) Grain Groups**

| Grain Group | Name | Color | Hex Code | Relationship |
|---|---|---|---|---|
| GP1M | Group 1 Milling | Gold | `#FFD700` | Lighter shade |
| GP2M | Group 2 Milling | Light Golden | `#F0C420` | Light-medium |
| GP3S | Group 3 Soft | Goldenrod | `#DAA520` | Base color |
| GP4H | Group 4 Hard | Dark Golden | `#C89F10` | Darker |
| GP4S | Group 4 Soft | Dark Goldenrod | `#B8860B` | Darkest |
| FDWHT | Feed Wheat | Light Goldenrod | `#EEDD82` | Pale |

**Example: OSR Grain Groups**

| Grain Group | Name | Color | Hex Code |
|---|---|---|---|
| OSR | Standard OSR | Gold | `#FFD700` |
| HEAR | High Erucic Acid | Light Yellow | `#FFEC8B` |
| HOLL | High Oleic Low Linolenic | Bright Yellow | `#FFE135` |

---

### Level 3: Variants (Patterns/Textures)

Variants get **patterns** rather than distinct colors, since there are 473 variants and too many colors would be confusing.

**Pattern Types:**

1. **Solid** - No pattern (default)
2. **Striped** - Horizontal stripes
3. **Dotted** - Small dots/stippling
4. **Checkered** - Grid/checkerboard pattern
5. **Diagonal** - Diagonal lines (45°)
6. **Crosshatch** - Crossed lines
7. **Wavy** - Wavy/undulating lines
8. **Zigzag** - Zigzag pattern
9. **Herringbone** - V-shaped pattern
10. **Brick** - Brick-like pattern

**Visual Representation:**
- Variant background color = Grain Group color
- Pattern overlay = Visual texture on top of background

**Example: GP1M Wheat Variants**
- ALCHEMY (GP1M) - Gold background, Solid
- ILLUSTRIOUS (GP1M) - Gold background, Striped
- MULIKA (GP1M) - Gold background, Dotted
- NELSON (GP1M) - Gold background, Checkered

---

## Implementation

### SQL Structure

Three pairs of tables created:

1. **Commodities**
   - `Commodities` - Main table (CommodityCode, CommodityName)
   - `CommodityAttributes` - Color attributes (BaseColour, ColourName)
   - `vw_Commodities` - Joined view

2. **GrainGroups**
   - `GrainGroups` - Main table (GrainGroupCode, GrainGroupName, CommodityID)
   - `GrainGroupAttributes` - Color attributes (BaseColour, ColourName)
   - `vw_GrainGroups` - Joined view with parent commodity

3. **Variants** (already exists)
   - `Variants` - Main table (VariantNo, GrainGroup, Commodity)
   - `VariantAttributes` - Color + Pattern attributes (BaseColour, Pattern, Notes)
   - `vw_Variants` - Joined view

### SQL Scripts

Run in this order:

```sql
-- 1. Create commodities tables and populate colors
-- C:\...\sql\create_commodities_tables.sql

-- 2. Create grain groups tables
-- C:\...\sql\create_graingroups_tables.sql

-- 3. Populate grain group colors
-- C:\...\sql\populate_graingroup_colors.sql

-- 4. Update variants table to add pattern support
-- C:\...\sql\update_variants_add_patterns.sql
```

### R Queries

Similar query functions should be created for commodities and grain groups:

**Commodities:**
- `list_commodities()` - List all commodities with colors
- `get_commodity()` - Get single commodity
- `update_commodity_attributes()` - Update color/notes

**Grain Groups:**
- `list_grain_groups()` - List all grain groups with colors
- `get_grain_group()` - Get single grain group
- `update_grain_group_attributes()` - Update color/notes

---

## Variant Data Reference

### Complete Variant List (473 items)

Stored for future reference and analysis. All variants from ID 474-946.

<details>
<summary>Click to expand full variant list</summary>

| ID | Variant | GrainGroup | Commodity |
|---|---|---|---|
| 474 | ACACIA | OSR | OSR |
| 475 | ADVANCE | OSR | OSR |
| 476 | ALCHEMY | GP4S | WHT |
| 477 | ALDERON | GP4H | WHT |
| 478 | ALEGRIA | OSR | OSR |
| 479 | ALICIUM | GP2M | WHT |
| 480 | ALIENOR | OSR | OSR |
| 481 | ALIZZE | OSR | OSR |
| 482 | AMALFI | FDPEAS | PEAS |
| 483 | AMALIE | OSR | OSR |
| 484 | AMBASSADOR | OSR | OSR |
| 485 | AMISTAR | FDBLY | FBLY |
| 486 | AMPLIFY | GP4H | WHT |
| 487 | ANASTASIA | OSR | OSR |
| 488 | ANGUS | OSR | OSR |
| 489 | AQUILA | OSR | OSR |
| 490 | ARAZZO | OSR | OSR |
| 491 | ARCHITECT | OSR | OSR |
| 492 | ASPEN | MILLINGOATS | OATS |
| 493 | ASPIRE OSR | OSR | OSR |
| 494 | ASTAIRE | FDBLY | FBLY |
| 495 | ASTEROID | ASTEROID | MBLY |
| 496 | ATEGO | MILLINGOATS | OATS |
| 497 | AURELIA | OSR | OSR |
| 498 | AVATAR | OSR | OSR |
| 499 | BABYLON | SPBNS | BNS |
| 500 | BALADO | MILLINGOATS | OATS |
| 501 | BALLAD | OSR | OSR |
| 502 | BAMFORD | GP3S | WHT |
| 503 | BARBADOS | OSR | OSR |
| 504 | BARLEY | FDBLY | FBLY |
| 505 | BARREL | GP3S | WHT |
| 506 | BASSET | GP3S | WHT |
| 507 | BATSMAN | LIN | LIN |
| 508 | BAZOOKA | FDBLY | FBLY |
| 509 | BEACON | MILLINGOATS | OATS |
| 510 | BEANS | FDBNS | BNS |
| 511 | BELEPI | GP4S | WHT |
| 512 | BELFRY | FDBLY | FBLY |
| 513 | BELGRADE | GP4H | WHT |
| 514 | BELGRAVIA | BELGRAVIA | MBLY |
| 515 | BELMONT | FDBLY | FBLY |
| 516 | BENNINGTON | GP4S | WHT |
| 517 | BEOWULF | GP4H | WHT |
| 518 | BINGO | LIN | LIN |
| 519 | BLAZEN | OSR | OSR |
| 520 | BLETCHLEY | FDWHT | WHT |
| 521 | BLUE PEAS | PEAS - HC | PEAS |
| 522 | BOLTON | FDBLY | FBLY |
| 523 | BONO | RYE | RYE |
| 524 | BOXER | SPBNS | BNS |
| 525 | BRITANNIA | GP3S | WHT |
| 526 | BROWN LINSEED | LIN | LIN |
| 527 | BUCCANEER | BUCCANEER | MBLY |
| 528 | BUMBLE | WINBNS | BNS |
| 529 | BUTTERFLY | OSR | OSR |
| 530 | CABERNET | OSR | OSR |
| 531 | CALIFORNIA | FDBLY | FBLY |
| 532 | CAMELOT | OSR | OSR |
| 533 | CAMPUS (OSR) | OSR | OSR |
| 534 | CAMPUS (PEAS) | PEAS - HC | PEAS |
| 535 | CANYON | MILLINGOATS | OATS |
| 536 | CARAT | CARAT | MBLY |
| 537 | CARTOUCHE | SPBNS | BNS |
| 538 | CASSATA | CASSATA | MBLY |
| 539 | CASSIA | FDBLY | FBLY |
| 540 | CATANA | OSR | OSR |
| 541 | CB SCORE | CBSCORE | MBLY |
| 542 | CHACHA | CHACHA | MBLY |
| 543 | CHAMPION | FDWHT | WHT |
| 544 | CHANSON | CHANSON | MBLY |
| 545 | CHAPEAU | CHAPEAU | MBLY |
| 546 | CHARGER | OSR | OSR |
| 547 | CHEER | GP1M | WHT |
| 548 | CHEERIO | CHEERIO | MBLY |
| 549 | CHILHAM | GP2M | WHT |
| 550 | CLAIRE | GP3S | WHT |
| 551 | CLEARFIELD | OSR | OSR |
| 552 | COCHISE | GP2M | WHT |
| 553 | COCOON | GP3S | WHT |
| 554 | COMPASS | OSR | OSR |
| 555 | CONCERTO | CONCERTO | MBLY |
| 556 | CONQUEROR | GP4H | WHT |
| 557 | CONSORT | GP3S | WHT |
| 558 | CONWAY | MILLINGOATS | OATS |
| 559 | COPINA | FDBLY | FBLY |
| 560 | CORDIALE | GP2M | WHT |
| 561 | COSMOPOLITAN | COSMOPOLITAN | FBLY |
| 562 | COSTELLO | GP4H | WHT |
| 563 | COSTELLO-GLYPHOSATE | GP4H | WHT |
| 564 | COUGAR | GP4S | WHT |
| 565 | CRAFT | CRAFT | MBLY |
| 566 | CRANIUM | GP4H | WHT |
| 567 | CRESWELL | FDBLY | FBLY |
| 568 | CRISPIN | GP4H | WHT |
| 569 | CROFT | GP3S | WHT |
| 570 | CRUSOE | GP1M | WHT |
| 571 | CUBANITA | GP2M | WHT |
| 572 | CUBIC | OSR | OSR |
| 573 | DALGUISE | MASCANI | OATS |
| 574 | DAWSUM WHEAT | GP4H | WHT |
| 575 | DAWSUM-GLYPHOSATE | GP4H | WHT |
| 576 | DAYTONA | PEAS - HC | PEAS |
| 577 | DELPHI | GP3S | WHT |
| 578 | DIABLO | DIABLO | MBLY |
| 579 | DICKENS | GP4H | WHT |
| 580 | DIEGO | GP4H | WHT |
| 581 | DIOPTRIC | DIOPTRIC | MBLY |
| 582 | DJANGO | OSR | OSR |
| 583 | DK EXENTIEL | OSR | OSR |
| 584 | DNS | IMP | WHT |
| 585 | DOUBLESHOT | GP1M | WHT |
| 586 | DRAGSTER | OSR | OSR |
| 587 | DUCHESS | LIN | LIN |
| 588 | DUNSTON | GP4H | WHT |
| 589 | DUPLO | OSR | OSR |
| 590 | DUROLA | HEAR | OSR |
| 591 | EDGAR | GP1M | WHT |
| 592 | ELECTRUM | ELECTRUM | MBLY |
| 593 | ELEVATION | OSR | OSR |
| 594 | ELGAR | OSR | OSR |
| 595 | ELICIT | GP3S | WHT |
| 596 | ELISE | OSR | OSR |
| 597 | ELYANN | SPRINGOATS | OATS |
| 598 | EMMA | LIN | LIN |
| 599 | ERATON | HEAR | OSR |
| 600 | ESCAPE | GP4H | WHT |
| 601 | EVOLUTION | GP4H | WHT |
| 602 | EXALTE | OSR | OSR |
| 603 | EXCALIBUR | OSR | OSR |
| 604 | EXCEL | OSR | OSR |
| 605 | EXCELLIUM | OSR | OSR |
| 606 | EXCLAIM | OSR | OSR |
| 607 | EXPEDIENT | OSR | OSR |
| 608 | EXPLORER | EXPLORER | MBLY |
| 609 | EXPOWER | OSR | OSR |
| 610 | EXSTAR | OSR | OSR |
| 611 | EXTASE | GP2M | WHT |
| 612 | EXTROVERT | OSR | OSR |
| 613 | FAIRING | FAIRING | MBLY |
| 614 | FANFARE | SPBNS | BNS |
| 615 | FASHION | OSR | OSR |
| 616 | FDBLY | FDBLY | FBLY |
| 617 | FDBNS | FDBNS | BNS |
| 618 | FDPEAS | FDPEAS | PEAS |
| 619 | FDWHT | FDWHT | WHT |
| 620 | FEED BARLEY | FDBLY | FBLY |
| 621 | FEED BEANS | FDBNS | BNS |
| 622 | FEED PEAS | FDPEAS | PEAS |
| 623 | FEED WHEAT | FDWHT | WHT |
| 624 | FENCER | OSR | OSR |
| 625 | FIREFLY | GP3S | WHT |
| 626 | FIRTH | MILLINGOATS | OATS |
| 627 | FLAGON | FLAGON | MBLY |
| 628 | FLAMINGO | OSR | OSR |
| 629 | FLETCHER | FDBLY | FBLY |
| 630 | FLORENTINE | FDBLY | FBLY |
| 631 | FLORIDA | OSR | OSR |
| 632 | FLYNN | FDBLY | FBLY |
| 633 | FREISTON | GP4H | WHT |
| 634 | FUEGO | SPBNS | BNS |
| 635 | FUNKY | FDBLY | FBLY |
| 636 | FURY | SPBNS | BNS |
| 637 | FUSION | MILLINGOATS | OATS |
| 638 | GALATION | FDBLY | FBLY |
| 639 | GALLANT | GP1M | WHT |
| 640 | GARNER | FDBLY | FBLY |
| 641 | GATOR | GP4H | WHT |
| 642 | GERALD | MILLINGOATS | OATS |
| 643 | GIMLET | FDBLY | FBLY |
| 644 | GLACIER | FDBLY | FBLY |
| 645 | GLEAM | GP4H | WHT |
| 646 | GLEAM-GLYPHOSATE | GP4H | WHT |
| 647 | GP1M | GP1M | WHT |
| 648 | GP2M | GP2M | WHT |
| 649 | GP3S | GP3S | WHT |
| 650 | GP4S | GP4S | WHT |
| 651 | GRAFTON | GP4H | WHT |
| 652 | GRAHAM | GP4H | WHT |
| 653 | GRANARY | GP2M | WHT |
| 654 | GRAVITY | GP4H | WHT |
| 655 | GREGOR | PEAS - HC | PEAS |
| 656 | GRIFFIN | MILLINGOATS | OATS |
| 657 | GROUP 1 | GP1M | WHT |
| 658 | GROUP 2 | GP2M | WHT |
| 659 | GROUP 3 SOFT | GP3S | WHT |
| 660 | GROUP 4 HARD | GP4H | WHT |
| 661 | GROUP 4 SOFT | GP4S | WHT |
| 662 | HACKER | FDBLY | FBLY |
| 663 | HARDWICKE | GP4S | WHT |
| 664 | HARNAS | OSR | OSR |
| 665 | HARPER | OSR | OSR |
| 666 | HAWKING | FDBLY | FBLY |
| 667 | HEAR OSR | HEAR | OSR |
| 668 | HOLL OSR | HOLL | OSR |
| 669 | HORATIO | GP4S | WHT |
| 670 | HYBIZA | FDWHT | WHT |
| 671 | HYLUX | FDWHT | WHT |
| 672 | HYTEK | GP3S | WHT |
| 673 | IC CANYON | IC OATS | ICOATS |
| 674 | IC COSTELLO | ICGP4H | ICWHT |
| 675 | IC EVOLUTION | ICGP4H | ICWHT |
| 676 | IC FDBLY | IC FDBLY | ICFBLY |
| 677 | IC FEED BEANS | ICFDBNS | ICBNS |
| 678 | IC FEED WHEAT | ICFDWHT | ICWHT |
| 679 | IC LAUREATE | IC LAUREATE | ICFBLY |
| 680 | IC MASCANI | IC OATS | ICOATS |
| 681 | IC MULIKA | IC GP1M | ICWHT |
| 682 | IC OATS | IC OATS | ICOATS |
| 683 | IC PLANET | IC PLANET | ICMBLY |
| 684 | IC PROPHET | IC PEAS - HC | ICPEAS |
| 685 | IC REVELATION | ICGP4S | ICWHT |
| 686 | IC SISKIN | ICGP2M | ICWHT |
| 687 | IC WESTMINSTER (BLY) | IC WESTMINSTER (BLY) | ICFBLY |
| 688 | ICFDBNS | ICFDBNS | ICBNS |
| 689 | ICFDWHT | ICFDWHT | ICWHT |
| 690 | ICON | ICFDWHT | ICWHT |
| 691 | ILLUSTRIOUS | GP1M | WHT |
| 692 | IMP | IMP | WHT |
| 693 | IMPERIAL | OSR | OSR |
| 694 | IMPRESSARIO | OSR | OSR |
| 695 | IMPRESSION | OSR | OSR |
| 696 | INCENTIVE | OSR | OSR |
| 697 | INFINITY | FDBLY | FBLY |
| 698 | INSITOR | GP4H | WHT |
| 699 | INV1035 | OSR | OSR |
| 700 | INVICTA | GP3S | WHT |
| 701 | IRINA | IRINA | MBLY |
| 702 | ISABEL | SPRINGOATS | OATS |
| 703 | ISTABRAQ | GP4S | WHT |
| 704 | JACKAL | GP3S | WHT |
| 705 | JIGSAW | GP4H | WHT |
| 706 | JULIET | LIN | LIN |
| 707 | KACTUS | PEAS - HC | PEAS |
| 708 | KARIOKA PEAS | PEAS - HC | PEAS |
| 709 | KAROIKA | FDPEAS | PEAS |
| 710 | KERRIN | GP4H | WHT |
| 711 | KIELDER | GP4H | WHT |
| 712 | KILBURN | GP4H | WHT |
| 713 | KINETIC | GP4H | WHT |
| 714 | KINGFISHER | FDPEAS | PEAS |
| 715 | KINGSBARN | FDBLY | FBLY |
| 716 | KWS TARDIS | FDBLY | FBLY |
| 717 | LADUM | GP1M | WHT |
| 718 | LAUREATE | LAUREATE | MBLY |
| 719 | LEEDS | GP4S | WHT |
| 720 | LENNOX | GP4H | WHT |
| 721 | LIBRA | FDBLY | FBLY |
| 722 | LILI | GP2M | WHT |
| 723 | LINEOUT | MILLINGOATS | OATS |
| 724 | LINSEED | LIN | LIN |
| 725 | LION | MILLINGOATS | OATS |
| 726 | LUSTRE | WW | WHT |
| 727 | LYNX | FDBNS | BNS |
| 728 | MAESTRO | MILLINGOATS | OATS |
| 729 | MAIZE | NULL | NULL |
| 730 | MALTING BARLEY | BARLEY | MBLY |
| 731 | MAMBO | OSR | OSR |
| 732 | MANAGER | PEAS - HC | PEAS |
| 733 | MANKATO PEAS | FDPEAS | PEAS |
| 734 | MARIS OTTER | MARIS OTTER | MBLY |
| 735 | MASCANI | MASCANI | OATS |
| 736 | MASCARA | PEAS - HC | PEAS |
| 737 | MATROS | MATROS | MBLY |
| 738 | MAYFLOWER | GP2M | WHT |
| 739 | MEMENTO | FDBLY | FBLY |
| 740 | MENTOR | OSR | OSR |
| 741 | MEPHISTO | RYE | RYE |
| 742 | MERIDIAN | MERIDIAN | MBLY |
| 743 | MERLIN | MILLINGOATS | OATS |
| 744 | MILLET | MILLET | MILL |
| 745 | MILLING OATS | MILLINGOATS | OATS |
| 746 | MONTANA | GP2M | WHT |
| 747 | MONTROSE | MILLINGOATS | OATS |
| 748 | MOTOWN | GP4S | WHT |
| 749 | MOULTON | GP4S | WHT |
| 750 | MULIKA | GP1M | WHT |
| 751 | MYRIAD | GP4S | WHT |
| 752 | NELSON | GP1M | WHT |
| 753 | NIKITA | OSR | OSR |
| 754 | NIL RETURN | FDWHT | WHT |
| 755 | OAKLEY | GP4H | WHT |
| 756 | OATS | MILLINGOATS | OATS |
| 757 | OCTAVIA | OCTAVIA | MBLY |
| 758 | ODYSSEY | ODYSSEY | MBLY |
| 759 | OG ARGENTINIAN | OG GP1M | OGWHT |
| 760 | OG ASTEROID | OG ASTEROID | OGMBLY |
| 761 | OG BEANS | OG BNS | OGBNS |
| 762 | OG CANYON | OG OATS | OGOATS |
| 763 | OG CHILHAM | OG GP2M | OGWHT |
| 764 | OG CLARE | OG GP2M | OGWHT |
| 765 | OG CONCERT | OG OATS | OGOATS |
| 766 | OG COSTELLO | OG GP4H | OGWHT |
| 767 | OG CRAFT | OGMB | OGMBLY |
| 768 | OG CRISPIN | OG GP4H | OGWHT |
| 769 | OG CRUSOE | OG GP1M | OGWHT |
| 770 | OG DELFIN | OG OATS | OGOATS |
| 771 | OG DELPHI | OG GP3S | OGWHT |
| 772 | OG DIABLO | OG FDBLY | OGFBLY |
| 773 | OG DUNSTON | OG GP4H | OGWHT |
| 774 | OG EAGLE OATS | OG OATS | OGOATS |
| 775 | OG EDGAR | OG GP1M | OGWHT |
| 776 | OG ELICIT | OG GP3S | OGWHT |
| 777 | OG ELYANN | OG OATS | OGOATS |
| 778 | OG EVOLUTION | OG GP4H | OGWHT |
| 779 | OG EXTASE | OG GP2M | OGWHT |
| 780 | OG FANFARE | OG SPGBNS | OGBNS |
| 781 | OG FDBLY | OG FDBLY | OGFBLY |
| 782 | OG FDBNS | OG FDBNS | OGBNS |
| 783 | OG FDWHT | OG FDWHT | OGWHT |
| 784 | OG FEED BARLEY | OG FDBLY | OGFBLY |
| 785 | OG FEED BEANS | OG FDBNS | OGBNS |
| 786 | OG FEED WHEAT | OG FDWHT | OGWHT |
| 787 | OG FIRTH | OG OATS | OGOATS |
| 788 | OG FLAGON | OG FLAGON | OGMBLY |
| 789 | OG FUEGO | OG SPGBNS | OGBNS |
| 790 | OG GERALD | OG OATS | OGOATS |
| 791 | OG GP1M | OG GP1M | OGWHT |
| 792 | OG GP3S | OG GP3S | OGWHT |
| 793 | OG GRIFFIN | OG OATS | OGOATS |
| 794 | OG GROUP 1 | OG GP1M | OGWHT |
| 795 | OG ILLUSTRIOUS | OG GP1M | OGWHT |
| 796 | OG ISABEL | OG OATS | OGOATS |
| 797 | OG LAUREATE | OG LAUREATE | OGMBLY |
| 798 | OG LILI | OG GP2M | OGWHT |
| 799 | OG MASCANI | OG OATS | OGOATS |
| 800 | OG MATROS | OG MATROS | OGFBLY |
| 801 | OG MB | OGMB | OGMBLY |
| 802 | OG MILLING | OG GP1M | OGWHT |
| 803 | OG MULIKA | OG GP1M | OGWHT |
| 804 | OG NELSON | OG GP1M | OGWHT |
| 805 | OG OATS | OG OATS | OGOATS |
| 806 | OG ODYSSEY | OG ODYSSEY | OGMBLY |
| 807 | OG OVATION (BLY) | OG OVATION (BLY) | OGFBLY |
| 808 | OG OVATION (WHT) | OG GP1M | OGWHT |
| 809 | OG PARAGON | OG GP1M | OGWHT |
| 810 | OG PEAS | OG PEAS | OGPEAS |
| 811 | OG PLANET | OG PLANET | OGMBLY |
| 812 | OG PROPINO | OG PROPINO | OGMBLY |
| 813 | OG QUENCH | OG QUENCH | OGMBLY |
| 814 | OG REVELATION | OG GP4S | OGWHT |
| 815 | OG RYE | OG RYE | OGRYE |
| 816 | OG SISKIN | OG GP2M | OGWHT |
| 817 | OG SKYFALL | OG GP4S | OGWHT |
| 818 | OG TALISMAN | OG TALISMAN | OGMBLY |
| 819 | OG TRITICALE | OGTRI | OGTRI |
| 820 | OG VENTURE | OG VENTURE | OGMBLY |
| 821 | OG VERTIGO | OG WINBNS | OGBNS |
| 822 | OG VICTUS | OG BNS | OGBNS |
| 823 | OG WESTMINSTER | OG WESTMINSTER | OGMBLY |
| 824 | OG WESTMINSTER (BLY) | OG WESTMINSTER (BLY) | OGMBLY |
| 825 | OG WIZARD (BNS) | OG WINBNS | OGBNS |
| 826 | OG YUKON | OG OATS | OGOATS |
| 827 | OG ZYATT | OG GP1M | OGWHT |
| 828 | OILSEED RAPE | OSR | OSR |
| 829 | OLIVIA | OSR | OSR |
| 830 | OLYMPUS | OLYMPUS | MBLY |
| 831 | OMEGALIN | LIN | LIN |
| 832 | OPERA | OPERA | MBLY |
| 833 | ORGANIC MAYFLOWER | OG GP2M | OGWHT |
| 834 | ORGANIC MERLIN | OG OATS | OGOATS |
| 835 | ORWELL | FDBLY | FBLY |
| 836 | OSR | OSR | OSR |
| 837 | OVATION (BARLEY) | FDBLY | FBLY |
| 838 | OVATION (OSR) | OSR | OSR |
| 839 | PALLADIUM | GP2M | WHT |
| 840 | PALMEDOR | HEAR | OSR |
| 841 | PANORAMA | GP2M | WHT |
| 842 | PARAGON | GP1M | WHT |
| 843 | PEAS | FDPEAS | PEAS |
| 844 | PEAS - HC | PEAS - HC | PEAS |
| 845 | PELOTON | MILLINGOATS | OATS |
| 846 | PHOENIX (OSR) | OSR | OSR |
| 847 | PHOENIX (RYE) | RYE | RYE |
| 848 | PICTO | OSR | OSR |
| 849 | PIZZARO | PEAS - HC | PEAS |
| 850 | PLANET | PLANET | MBLY |
| 851 | POPULAR | OSR | OSR |
| 852 | PR46W21 | OSR | OSR |
| 853 | PRELADO | FDPEAS | PEAS |
| 854 | PROPHET | PEAS - HC | PEAS |
| 855 | PROPINO | PROPINO | MBLY |
| 856 | PT211 | OSR | OSR |
| 857 | PT303 | OSR | OSR |
| 858 | PX113 | OSR | OSR |
| 859 | PYRAMID | SPBNS | BNS |
| 860 | QUADRA | FDBLY | FBLY |
| 861 | QUARTZ | OSR | OSR |
| 862 | QUENCH | QUENCH | MBLY |
| 863 | REFLECTION | GP4H | WHT |
| 864 | RELAY | GP4H | WHT |
| 865 | REVELATION | GP4S | WHT |
| 866 | RIVALDA | OSR | OSR |
| 867 | ROBIGUS | GP3S | WHT |
| 868 | ROSE | ROSE | MBLY |
| 869 | ROZMAR | MILLINGOATS | OATS |
| 870 | RYE | RYE | RYE |
| 871 | SAKI | GP4S | WHT |
| 872 | SAKURA | FDPEAS | PEAS |
| 873 | SANETTE | SANETTE | MBLY |
| 874 | SANTIAGO | GP4H | WHT |
| 875 | SARTORIAL | GP4H | WHT |
| 876 | SASSY | SASSY | MBLY |
| 877 | SAVELLO | GP4S | WHT |
| 878 | SBLY | SBLY | MBLY |
| 879 | SCHOLAR | FDBLY | FBLY |
| 880 | SCOUT | GP3S | WHT |
| 881 | SECRET | OSR | OSR |
| 882 | SESAME | OSR | OSR |
| 883 | SHABRAS | GP4H | WHT |
| 884 | SIDERAL | LIN | LIN |
| 885 | SIENNA | SIENNA | MBLY |
| 886 | SILVERSTONE | GP4H | WHT |
| 887 | SISKIN | GP2M | WHT |
| 888 | SKYFALL | GP1M | WHT |
| 889 | SKYSCRAPER | GP4S | WHT |
| 890 | SKYWAY | SKYWAY | MBLY |
| 891 | SOISSONS | GP2M | WHT |
| 892 | SOLSTICE | GP1M | WHT |
| 893 | SPBNS | SPBNS | BNS |
| 894 | SPOTLIGHT | GP4S | WHT |
| 895 | SPRING BARLEY | SPRINGBLY | MBLY |
| 896 | SPRING BEANS | SPBNS | BNS |
| 897 | SPRING OATS | MILLINGOATS | OATS |
| 898 | SPYDER | GP3S | WHT |
| 899 | SUNDANCE | GP4S | WHT |
| 900 | SUNNINGDALE | FDBLY | FBLY |
| 901 | SURGE | FDBLY | FBLY |
| 902 | SY SPLENDOR | FDBLY | FBLY |
| 903 | TACTIC | OSR | OSR |
| 904 | TALISMAN | TALISMAN | MBLY |
| 905 | TARGET | GP3S | WHT |
| 906 | TIPPLE | TIPPLE | MBLY |
| 907 | TOWER | FDBLY | FBLY |
| 908 | TRI | TRI | TRI |
| 909 | TRINITY (OSR) | OSR | OSR |
| 910 | TRINITY (WHT) | GP1M | WHT |
| 911 | TRITICALE | TRI | TRI |
| 912 | TROY | OSR | OSR |
| 913 | TUNDRA | FDBNS | BNS |
| 914 | TUXEDO | GP3S | WHT |
| 915 | TYBALT | GP2M | WHT |
| 916 | TYPHOON | GP4H | WHT |
| 917 | VALERIE | FDBLY | FBLY |
| 918 | VAUGHAN | MILLINGOATS | OATS |
| 919 | VENTURE | VENTURE | MBLY |
| 920 | VERTIGO | FDBNS | BNS |
| 921 | VESPA | FDBNS | BNS |
| 922 | VICTORIOUS | MILLINGOATS | OATS |
| 923 | VISCOUNT | GP4S | WHT |
| 924 | VISION | OSR | OSR |
| 925 | VOLUME | FDBLY | FBLY |
| 926 | WARBURTONS CRUSOE | WARB | WHT |
| 927 | WARBURTONS ILLUST | WARB | WHT |
| 928 | WARBURTONS LOXTON | WARB | WHT |
| 929 | WARBURTONS PALLADIUM | WARB | WHT |
| 930 | WARBURTONS SKYFALL | WARB | WHT |
| 931 | WARRIOR | GP3S | WHT |
| 932 | WCAN | IMP | WHT |
| 933 | WEMBLEY | OSR | OSR |
| 934 | WESTMINSTER (BLY) | WESTMINSTER (BLY) | MBLY |
| 935 | WESTMINSTER (WHT) | GP4S | WHT |
| 936 | WHEAT | FDWHT | WHT |
| 937 | WILLOW | GP2M | WHT |
| 938 | WINDOZZ | OSR | OSR |
| 939 | WIZARD (BNS) | SPBNS | BNS |
| 940 | WOLVERINE | GP4H | WHT |
| 941 | WW | WW | WHT |
| 942 | WW25 | WW | WHT |
| 943 | XI-19 | GP1M | WHT |
| 944 | YUKON | MILLINGOATS | OATS |
| 945 | ZULU | GP3S | WHT |
| 946 | ZYATT | GP1M | WHT |

</details>

---

## Next Steps

1. **Run SQL scripts** to create tables and populate color data
2. **Create R query functions** for commodities and grain groups (similar to variants_queries.R)
3. **Create browser tabs** for commodities and grain groups (similar to f_browser_variants.R)
4. **Implement color picker** in variants browser using grain group colors as defaults
5. **Add pattern picker** for variants (dropdown or visual selector)
6. **Create visual legend** showing commodity colors and grain group shades

---

## Notes

- All color codes are standard hex format (#RRGGBB)
- Colors designed for accessibility and visual distinction
- Patterns allow unlimited variants without color confusion
- Hierarchy maintained: Variant → Grain Group → Commodity
- Data stored for future reference and is stable

