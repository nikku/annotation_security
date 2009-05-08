AnnotationSecurity.define_relations do

  # All relations are defined in the context of a resource.
  # The proc should return true iif the user has this relations.

  all_resources do
    # A user is responsible if he is corrector or lecturer for a resource.
    # The relations #corrector and #lecturer must be defined by that resource.
    responsible(:pretest) {corrector or lecturer}

    frau_pamperin(:system) { |user| user.name == "Frau Pamperin" }
    student(:system, :as => :student)
    corrector(:system, :as => :corrector)
    lecturer(:system, :as => :lecturer)
    administrator(:system, :is => :administrator)
  end

  resource :assignment_result do
    owner :as => :student do |student,result|
      result.student == student
    end

#    enrolled "if enrolled(:resource.assignment.course)"
#    enrolled "if enrolled: assignment.course"

    enrolled "if enrolled: assignment.course"
    corrector "if corrector(:resource.assignment.corrector)"
    lecturer "if lecturer(:resource.assignment.course)"
  end

  resource :assignment do
    enrolled "if enrolled: course"
    corrector "if corrector: course"
    lecturer "if lecturer: course"
  end

  resource :course do
    enrolled :as => :student do |student,course|
      student.enrolled? course
    end

    corrector :as => :corrector do |corrector,course|
      corrector.corrects? course
    end

    lecturer :as => :lecturer do |lecturer,course|
      lecturer.lectures? course or course.lecturers.include? lecturer
    end
  end
end
