# Determinants of Medical Expenditure Among Medicare Beneficiaries

**Author:** Andres Jimenez  
**Date:** October 2025

## 📋 Overview

This project examines the determinants of medical expenditure among Medicare-eligible individuals aged 65 and older. Using data from 3,064 Medicare beneficiaries, I investigate how health limitations, chronic conditions, and demographic characteristics influence healthcare spending patterns.

### Key Findings

- Health status explains 22% of expenditure variation
- Each chronic condition increases expenditure by 46%
- Functional limitations independently drive costs beyond diagnoses
- Age has minimal effect after controlling for health status
- Retirement increases expenditure by 38% for males but only 8% for females

## 📊 Main Results

**Full Model Results (N=2,955, R²=0.221)**

| Variable | Effect on Expenditure | Significance |
|----------|----------------------|--------------|
| Each Chronic Condition | +46.2% | *** |
| Physical Limitation | +36.7% | *** |
| Activity Limitation | +40.5% | *** |
| Female (vs Male) | -9.3% | ** |
| Each $1,000 Income | +0.4% | *** |
| Age | +0.2% | not significant |

*** p<0.01, ** p<0.05

### Health Risk Groups

| Risk Level | Mean Expenditure | % of Sample |
|------------|------------------|-------------|
| Low (0 conditions) | $2,519 | 18% |
| Medium (1-2 conditions) | $6,147 | 55% |
| High (3+ conditions) | $11,928 | 27% |

High-risk beneficiaries spend **4.7x more** than low-risk.

## 🎯 Policy Implications

1. **Target chronic disease management** - Each condition adds $1,150 annually
2. **Support functional independence** - Physical/occupational therapy reduces costs
3. **Focus on prevention** - Age itself doesn't drive costs; preventing conditions does
4. **Stratify interventions** - High-risk 27% drive disproportionate costs

## 🛠️ Methodology

- **Sample**: 3,064 Medicare beneficiaries aged 65-90
- **Methods**: OLS regression, quantile regression, interaction analysis
- **Software**: Stata 17
- **Models**: Progressive specifications from baseline to full controls

## 📁 Repository Contents

- `code/` - Stata analysis script
- `tables/` - Regression tables (RTF format)
- `figures/` - 7 publication-quality figures
- `paper/` - Full research paper (PDF)

## 📧 Contact

**Andres Jimenez**  
[Add your email here]

## 📜 License

MIT License - See LICENSE file for details

---

*Undergraduate research project, Economics 650-01*
