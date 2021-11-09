    def to_string(self):
        s = []
        s.append("require {")
        for bool in sorted(self.data):
            s.append("\tbool %s;" % bool)
        for obj_class, perms in sorted(self.obj_classes.items(), key=lambda x: x[0]):
            s.append("\tclass %s %s;" % (obj_class, perms.to_space_str()))
        for role in sorted(self.roles):
            s.append("\trole %s;" % role)
        for type in sorted(self.types):
            s.append("\ttype %s;" % type)
        for user in sorted(self.users):
            s.append("\tuser %s;" % user)
        s.append("}")
