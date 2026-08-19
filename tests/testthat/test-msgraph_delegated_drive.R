test_that("msgraph_site_lookup_url baut die Graph-Site-URL aus der Site-URL", {
  expect_equal(
    MSGraph:::msgraph_site_lookup_url("https://studyflix.sharepoint.com/sites/StudyflixCloud"),
    "https://graph.microsoft.com/v1.0/sites/studyflix.sharepoint.com:/sites/StudyflixCloud")
  expect_equal(
    MSGraph:::msgraph_site_lookup_url("https://studyflix.sharepoint.com/sites/StudyflixCloud/"),
    "https://graph.microsoft.com/v1.0/sites/studyflix.sharepoint.com:/sites/StudyflixCloud")
  expect_error(MSGraph:::msgraph_site_lookup_url("https://studyflix.sharepoint.com"),
               "Site-Pfad")
})
