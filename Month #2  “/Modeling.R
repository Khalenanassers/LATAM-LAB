

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(lattice)
})


FILE_PATH    <- "D:/2doBrain/KNS Brain/02 - Projects/LATAM Lab-subfolders/M02+Chustomer Churn/IBM Churn/WA_Fn-UseC_-Telco-Customer-Churn.csv"
DATASET_NAME <- "IBM Telco -- LATAM Lab M2"

df  <- load_data(FILE_PATH)

# 2. Select only the mathematically proven features
df_model <- df %>%
  select(
    Churn,               # Target
    tenure,              # Numerical 1
    MonthlyCharges,      # Numerical 2
    Contract,            # Categorical (V = 0.410)
    OnlineSecurity,      # Categorical (V = 0.347)
    TechSupport,         # Categorical (V = 0.343)
    InternetService,     # Categorical (V = 0.322)
    PaymentMethod        # Categorical (V = 0.303)
  )

# 3. Ensure target is a proper factor (0 and 1, or "No" and "Yes")
df_model$Churn <- as.factor(df_model$Churn)

# 4. Check for missing values in this clean subset
sum(is.na(df_model))

# Look at your new, lean data set
str(df_model)

set.seed(2995)

# 1. Split 70% Train, 20% Test
sample_size <- floor(0.70 * nrow(df_model))
train_indices <- sample(seq_len(nrow(df_model)), size = sample_size)

train_data <- df_model[train_indices, ]
test_data  <- df_model[-train_indices, ]

## 2. Scale the numerical features (prevents MonthlyCharges from overpowering tenure)
mean_tenure <- mean(train_data$tenure)
sd_tenure <- sd(train_data$tenure)

mean_mc <- mean(train_data$MonthlyCharges)
sd_mc <- sd(train_data$MonthlyCharges)

# Apply scaling to Train data
train_data$tenure <- (train_data$tenure - mean_tenure) / sd_tenure
train_data$MonthlyCharges <- (train_data$MonthlyCharges - mean_mc) / sd_mc

# Apply scaling to Test data
test_data$tenure <- (test_data$tenure - mean_tenure) / sd_tenure
test_data$MonthlyCharges <- (test_data$MonthlyCharges - mean_mc) / sd_mc


# Train the Logistic Regression using base R's 'glm' function
logit_model <- glm(Churn ~ ., data = train_data, family = "binomial")

# View the results
summary(logit_model)

# Prediction
probabilities <- predict(logit_model, newdata = test_data, type = "response")
predictions <- ifelse(probabilities > 0.3, "Yes", "No")

# 3. Create the Confusion Matrix (Grade the exam)
actuals <- test_data$Churn
conf_matrix <- table(Predicted = predictions, Actual = actuals)

print("--- CONFUSION MATRIX ---")
print(conf_matrix)

# 4. Calculate Overall Accuracy 
# (Total Correct Guesses / Total Total Guesses)
accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)
print(paste("Overall Accuracy:", round(accuracy * 100, 2), "%"))


# So, the overall accuracy of our model is around 75.03%, which means that out of all the customers in the test set, correctly classified as either Churn or No Churn based on our model's predictions.
# Change the threshold to 0.3, which means that if the predicted probability of Churn is greater than 30%, we classify that customer as "Yes" for Churn; otherwise, we classify them as "No". So the model can be better at predict False Negatives and True Positives. It hit accuracy but avoid financial losses, focus on Recall 
#The only flaw left in the current matrix is the 395 False Positive 

library(randomForest)

set.seed(2995)

# Train the Random Forest
# ntree = 500: Build 500 different decision trees/standart number
# importance = TRUE: Calculate which features are the most important

rf_model <- randomForest(Churn ~ ., 
                         data = train_data, 
                         ntree = 500, 
                         importance = TRUE)

print(rf_model)

# 1. Get the predicted probabilities from the Random Forest
# type = "prob" returns two columns (Prob of No, Prob of Yes). We want column 2 (Yes).
rf_probabilities <- predict(rf_model, newdata = test_data, type = "prob")[, "Yes"]

# 2. Apply your custom business threshold (e.g., > 0.30)
# Feel free to adjust this 0.30 to whatever exact number you used in the last step!
rf_predictions <- ifelse(rf_probabilities > 0.30, "Yes", "No")

# 3. Create the Confusion Matrix
rf_conf_matrix <- table(Predicted = rf_predictions, Actual = test_data$Churn)

print("--- RANDOM FOREST CONFUSION MATRIX ---")
print(rf_conf_matrix)

# 4. Calculate overall accuracy
rf_accuracy <- sum(diag(rf_conf_matrix)) / sum(rf_conf_matrix)
print(paste("Random Forest Accuracy:", round(rf_accuracy * 100, 2), "%"))

# Plot the importance of the features
varImpPlot(rf_model, main = "What Drives Churn? (Random Forest)")

# Show exactly how 'tenure' changes the probability of churn
partialPlot(rf_model, train_data, x.var = "tenure", which.class = "Yes",
            main = "How Tenure Impacts Churn Probability",
            xlab = "Tenure (Standardized)", ylab = "Effect on Churn")



library(xgboost)

set.seed(2995)

# 2. Convert categorical features to 0s and 1s automatically using Base R's model.matrix
# The '- 1' at the end just tells R not to add a mathematical intercept column
train_matrix <- model.matrix(Churn ~ tenure + MonthlyCharges + Contract + 
                               OnlineSecurity + TechSupport + InternetService + 
                               PaymentMethod - 1, data = train_data)

test_matrix  <- model.matrix(Churn ~ tenure + MonthlyCharges + Contract + 
                               OnlineSecurity + TechSupport + InternetService + 
                               PaymentMethod - 1, data = test_data)

# 2. Reset y_train and y_test back to their original Categories (Factors)
y_train <- train_data$Churn
y_test  <- test_data$Churn

# 3. Train the model again! (It will now recognize the Categories)
xgb_model <- xgboost(x = train_matrix, 
                     y = y_train,
                     nrounds = 100,                 
                     objective = "binary:logistic", 
                     max_depth = 4,                 
                     learning_rate = 0.1,           
                     eval_metric = "auc")           

# 4. Check Feature Importance
importance_matrix <- xgb.importance(feature_names = colnames(train_matrix), model = xgb_model)


# 5. Plot it!
xgb.plot.importance(importance_matrix, top_n = 10, main = "Top 10 Drivers of Churn (XGBoost)")


# 1. Generate probabilities using the test data
# Note: Even though only 4 features are important, we still pass the whole test_matrix 
# because the model expects the exact same columns it was trained on.
predicted_probs <- predict(xgb_model, test_matrix)

# Let's look at the first 5 predictions just to see what they look like
head(predicted_probs)

# 2. Convert probabilities into hard "Yes" or "No" predictions (using a 50% threshold)
# If probability > 0.5, predict "Yes", otherwise "No"
predicted_classes <- ifelse(predicted_probs > 0.3, "Yes", "No")
predicted_classes <- as.factor(predicted_classes)

# 3. Compare predictions against the ACTUAL test answers to get our Accuracy
# We use Base R's table function to build a "Confusion Matrix"
actual_answers <- y_test 
confusion_matrix <- table(Predicted = predicted_classes, Actual = actual_answers)

# Print the Confusion Matrix
print("Confusion Matrix:")
print(confusion_matrix)

# 4. Calculate overall accuracy
accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
print(paste("Overall Accuracy:", round(accuracy * 100, 2), "%"))
